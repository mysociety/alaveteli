namespace :users do
  namespace :sign_ins do
    desc 'Purge sign in activity records outside the retention period'
    task purge: :environment do
      User::SignIn.purge
    end
  end
end
