module User::Unused
  extend ActiveSupport::Concern

  class_methods do
    # return an array of unused users i.e. users without any user generated
    # content, without granted an user role or recent sign ins
    def unused
      citations = Citation.arel_table
      citations_exists = citations.project(1).
        where(citations[:user_id].eq(User.arel_table[:id])).
        exists

      # don't return admins, pro admins, pros
      roles = Role.arel_table
      user_roles = Arel::Table.new(:users_roles)
      user_roles_exists = user_roles.project(1).
        join(roles).on(user_roles[:role_id].eq(roles[:id])).
        where(user_roles[:user_id].eq(User.arel_table[:id])).
        where(roles[:name].in(%w[admin pro_admin pro])).
        exists

      # don't return users who have previous submissions to a project
      submission = Project::Submission.arel_table
      submission_exists = submission.project(1).
        where(submission[:user_id].eq(User.arel_table[:id])).
        exists

      # don't return users who have signed in recently
      sign_ins = User::SignIn.arel_table
      sign_ins_exists = sign_ins.project(1).
        where(sign_ins[:user_id].eq(User.arel_table[:id])).
        exists

      User.
        where.not(email: internal_admin_user.email).
        where(info_requests_count: 0).
        where(info_request_batches_count: 0).
        where(request_classifications_count: 0).
        where(status_update_count: 0).
        where(track_things_count: 0).
        where(comments_count: 0).
        where(public_body_change_requests_count: 0).
        where.not(citations_exists).
        where.not(user_roles_exists).
        where.not(submission_exists).
        where.not(sign_ins_exists)
    end
  end
end
