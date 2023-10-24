# Controller to render the changelog notes in a more human-friendly way within
# the admin interface.
class Admin::ChangelogController < AdminController
  def index
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)
    text = File.read(Rails.root + 'doc/CHANGES.md')
    @changelog = markdown.render(text).html_safe
  end
end
