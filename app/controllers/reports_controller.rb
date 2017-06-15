# -*- encoding : utf-8 -*-
class ReportsController < ApplicationController
  before_filter :set_info_request
  before_filter :set_comment
  before_filter :set_reportable
  before_filter :set_report_reasons

  def create
    @reason = params[:reason]
    @message = params[:message] || ""
    if @reason.empty?
      flash[:error] = _("Please choose a reason")
      render "new"
      return
    end
    if !authenticated_user
      flash[:notice] = _("You need to be logged in to report a request for administrator attention")
    elsif @info_request.attention_requested
      flash[:notice] = _("This request has already been reported for administrator attention")
    else
      @reportable.report!(@reason, @message, @user)
      flash[:notice] = if @comment
        _("This annotation has been reported for administrator attention")
      else
        _("This request has been reported for administrator attention")
      end
    end
    redirect_to request_url(@info_request)
  end

  def new
    @title = if @comment
      _("Report annotation on request: {{title}}",
        :title => @info_request.title)
    else
      _("Report request: {{title}}", :title => @info_request.title)
    end

    if authenticated?(
      :web => _("To report this request"),
      :email => _("Then you can report the request '{{title}}'", :title => @info_request.title),
      :email_subject => _("Report an offensive or unsuitable request"),
      :comment_id => params[:comment_id])
    end
  end

  private

  def set_info_request
    @info_request = InfoRequest
                      .not_embargoed
                        .find_by_url_title!(params[:request_id])
  end

  def set_comment
    @comment = unless params[:comment_id].blank?
      @info_request.comments.where(:id => params[:comment_id]).first!
    end
  end

  def set_reportable
    @reportable = @comment || @info_request
  end

  def set_report_reasons
    @report_reasons = @reportable.report_reasons
  end
end
