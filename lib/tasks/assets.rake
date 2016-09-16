#
# Copyright 2015, SUSE Linux GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

namespace :assets do
  def available_assets
    Pathname.glob(
      Rails.root.join(
        "public",
        "assets",
        "**",
        "*"
      )
    )
  end

  def digested_regex
    /(-{1}[a-z0-9]{32}*\.{1}){1}/
  end

  task setup_logger: :environment do
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  task non_digested: :setup_logger do
    available_assets.each do |asset|
      next if asset.directory?
      next unless asset.to_s =~ digested_regex

      simple = asset.dirname.join(
        asset.basename.to_s.gsub(digested_regex, ".")
      )

      if simple.exist?
        simple.delete
      end

      @logger.info "Symlinking #{simple}"
      simple.make_symlink(asset.basename)
    end
  end

  task clean_dangling: :setup_logger do
    available_assets.each do |asset|
      next if asset.directory?
      next if asset.to_s =~ digested_regex

      next unless asset.symlink?

      # exist? is enough for checking the symlink target as it resolves the
      # link target and checks if that really exists. The check for having a
      # symlink is already done above.
      unless asset.exist?
        @logger.info "Removing #{asset}"
        asset.delete
      end
    end
  end
end

Rake::Task["assets:precompile"].enhance do
  Rake::Task["assets:non_digested"].invoke
  Rake::Task["assets:clean_dangling"].invoke
end
