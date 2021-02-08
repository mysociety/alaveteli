# Controller for managing OutgoingMessage::Snippet records
class Admin::OutgoingMessages::SnippetsController < AdminController
  def index
    @title = 'Listing Snippets'
    @snippets = OutgoingMessage::Snippet.
      paginate(page: params[:page], per_page: 25)
  end
end
