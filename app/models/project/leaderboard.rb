##
# Export a project's leaderboard of classifications and data extractions to CSV.
#
class Project::Leaderboard
  include DownloadHelper

  attr_reader :project
  protected :project

  def initialize(project)
    @project = project
  end

  def all_time
    @leaderboard_all_time ||= data.first(5)
  end

  def twenty_eight_days
    @leaderboard_28_days ||= data(
      project.submissions.where(created_at: 28.days.ago..)
    ).first(5)
  end

  def name
    generate_download_filename(
      resource: 'project-leaderboard',
      id: project.id,
      title: project.title,
      ext: 'csv'
    )
  end

  def to_csv
    CSV.generate do |csv|
      header = data.first
      csv << header.keys.map(&:to_s) if header
      data.each do |row|
        row[:user] = row[:user].name
        csv << row.values
      end
    end
  end

  private

  def data(scope = project.submissions)
    leaderboard = project.members.map do |user|
      user_scope = scope.where(user_id: user.id)
      {
        user: user,
        classifications: user_scope.classification.size,
        extractions: user_scope.extraction.size,
        total_contributions: user_scope.size
      }
    end
    leaderboard.sort_by { |row| row[:total_contributions] }.reverse
  end
end
