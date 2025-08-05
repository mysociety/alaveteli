# -*- encoding : utf-8 -*-
module AlaveteliPro
  module ActivityList
    class Comment < Item

      def description
        if event.comment.user == event.info_request.user
          N_('You added a new annotation on your request to ' \
             '{{public_body_name}} "{{info_request_title}}."')
        else
          N_('{{commenter_name}} added a new annotation on your request to ' \
             '{{public_body_name}} "{{info_request_title}}."')
        end
      end

      def description_urls
        { :public_body_name => { :text => body_name, :url => body_path },
          :info_request_title => { :text => info_request_title, :url => info_request_path },
          :commenter_name => { :text => event.comment.user.name, :url => user_path(event.comment.user) } }
      end

      def call_to_action_url
        comment_path(event.comment)
      end

    end
  end
end
