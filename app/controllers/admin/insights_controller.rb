##
# Controller for running AI insights tasks from the admin UI
#
class Admin::InsightsController < AdminController
  before_action :find_info_request
  before_action :find_insight, only: [:show, :destroy]

  def show
  end

  def new
    last = Insight.last
    @insight = @info_request.insights.new(
      model: last&.model, temperature: last&.temperature || 0.3,
      prompt_template: last&.prompt_template
    )
  end

  def create
    @insight = @info_request.insights.new(insight_params)
    if @insight.save
      redirect_to admin_info_request_insight_path(@info_request, @insight),
                  notice: 'Insight was successfully created.'
    else
      render :new
    end
  end

  def destroy
    @insight.destroy
    redirect_to admin_request_path(@info_request),
                notice: 'Insight was successfully deleted.'
  end

  private

  def find_info_request
    @info_request = InfoRequest.find(params[:info_request_id])
  end

  def find_insight
    @insight = @info_request.insights.find(params[:id])
  end

  def insight_params
    params.require(:insight).permit(:model, :temperature, :prompt_template)
  end
end
