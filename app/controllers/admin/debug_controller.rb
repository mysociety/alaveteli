class Admin::DebugController < AdminController
  def index
    @admin_current_user = admin_current_user
    @current_commit = Statistics::General.new.to_h[:alaveteli_git_commit]
    @current_branch = `git branch | perl -ne 'print $1 if /^\\* (.*)/'`
    @current_version = ALAVETELI_VERSION
    repo = `git remote show origin -n | perl -ne 'print $1 if m{Fetch URL: .*github\\.com[:/](.*)\\.git}'`
    @github_origin = "https://github.com/#{repo}/tree/"
    @request_env = request.env
  end
end
