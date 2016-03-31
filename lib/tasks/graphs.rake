# -*- encoding : utf-8 -*-

require File.join(File.dirname(__FILE__), '../graphs')

namespace :graphs do
  include Graphs

  task :generate_user_use_graph => :environment do
    # set the local font path for the current task
    ENV["GDFONTPATH"] = "/usr/share/fonts/truetype/ttf-bitstream-vera"

    active_users = "SELECT DATE(created_at), COUNT(distinct user_id) " \
                   "FROM info_requests GROUP BY DATE(created_at) " \
                   "ORDER BY DATE(created_at)"

    confirmed_users = "SELECT DATE(created_at), COUNT(*) FROM users " \
                      "WHERE email_confirmed = 't' " \
                      "GROUP BY DATE(created_at) " \
                      "ORDER BY DATE(created_at)"

    # here be database-specific dragons...
    # this uses a window function which is not supported by MySQL, but
    # is reportedly available in MariaDB from 10.2 onward (and Postgres 9.1+)
    aggregate_signups = "SELECT DATE(created_at), COUNT(*), SUM(count(*)) " \
                        "OVER (ORDER BY DATE(created_at)) " \
                        "FROM users GROUP BY DATE(created_at)"

    Gnuplot.open(false) do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal("png font 'Vera.ttf' 9 size 1200,400")
        plot.output(File.expand_path("public/foi-user-use.png", Rails.root))

        #general settings
        plot.unset(:border)
        plot.unset(:arrow)
        plot.key("left")
        plot.tics("out")

        # x-axis
        plot.xdata("time")
        plot.set('timefmt "%Y-%m-%d"')
        plot.set('format x "%d %b %Y"')
        plot.set("xtics nomirror")

        # primary y-axis
        plot.set("ytics nomirror")
        plot.ylabel("number of users on the calendar day")
        plot.yrange("[0:]")

        # secondary y-axis
        plot.set("y2tics tc lt 2")
        plot.set('y2label "cumulative total number of users" tc lt 2')
        plot.set('format y2 "%.0f"')
        plot.y2range("[0:]")

        # start plotting the data from largest to smallest so
        # that the shorter bars overlay the taller bars

        state_list = [ {
                          :title => "users each day ... who registered",
                          :colour => :lightblue
                        },
                        {
                          :title => "... and since confirmed their email",
                          :with => "impulses",
                          :linewidth => 15,
                          :colour => :mauve,
                          :sql => confirmed_users
                        },
                        {
                          :title => "...who made an FOI request",
                          :with => "lines",
                          :linewidth => 1,
                          :colour => :red,
                          :sql => active_users
                        }
                      ]

        # plot all users
        options = {:with => "impulses",
                   :linecolor => COLOURS[state_list[0][:colour]],
                   :linewidth => 15, :title => state_list[0][:title]}
        all_users = select_as_columns(aggregate_signups)

        # nothing to do, bail
        abort "warning: no user data to graph, skipping task" unless all_users

        plot_data_from_columns(all_users, options, plot.data)

        graph_param_sets = []
        state_list.each_with_index do |state_info, index|
          if index > 0
            graph_param_sets << GraphParams.new(
              state_info[:sql],
              options.merge({
                :title => state_info[:title],
                :linecolor => COLOURS[state_info[:colour]],
                :with => state_info[:with],
                :linewidth => state_info[:linewidth]})
            )
          end
        end

        plot_datasets(graph_param_sets, plot.data)

        # plot cumulative user totals
        options.merge!({
          :title => "cumulative total number of users",
          :axes => "x1y2",
          :with => "lines",
          :linewidth => 1,
          :linecolor => COLOURS[:lightgreen],
          :using => "1:3"})
        plot_data_from_columns(all_users, options, plot.data)
      end
    end
  end

  task :generate_request_creation_graph => :environment do
    # set the local font path for the current task
    ENV["GDFONTPATH"] = "/usr/share/fonts/truetype/ttf-bitstream-vera"

    def assemble_sql(where_clause="")
      "SELECT DATE(created_at), COUNT(*) " \
              "FROM info_requests " \
              "WHERE #{where_clause} " \
              "AND PROMINENCE != 'backpage' " \
              "GROUP BY DATE(created_at)" \
              "ORDER BY DATE(created_at)"
    end

    def state_exclusion_sql(states)
      "described_state NOT IN ('#{states.join("','")}')"
    end

    Gnuplot.open(false) do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal("png font 'Vera.ttf' 9 size 1600,600")
        plot.output(File.expand_path("public/foi-live-creation.png", Rails.root))

        #general settings
        plot.unset(:border)
        plot.unset(:arrow)
        plot.key("left")
        plot.tics("out")

        # x-axis
        plot.xdata("time")
        plot.set('timefmt "%Y-%m-%d"')
        plot.set('format x "%d %b %Y"')
        plot.set("xtics nomirror")
        plot.xlabel("status of requests that were created on each calendar day")

        # primary y-axis
        plot.ylabel("number of requests created on the calendar day")
        plot.yrange("[0:]")

        # secondary y-axis
        plot.set("y2tics tc lt 2")
        plot.set('y2label "cumulative total number of requests" tc lt 2')
        plot.set('format y2 "%.0f"')
        plot.y2range("[0:]")

        # get the data, plot the graph

        state_list = [ {:state => 'waiting_response', :colour => :darkblue},
                   {:state => 'waiting_clarification', :colour => :lightblue},
                   {:state => 'not_held',  :colour => :yellow},
                   {:state => 'rejected', :colour =>  :red},
                   {:state => 'successful',  :colour => :lightgreen},
                   {:state => 'partially_successful',  :colour => :darkgreen},
                   {:state => 'requires_admin', :colour =>  :cyan},
                   {:state => 'gone_postal',  :colour => :darkyellow},
                   {:state => 'internal_review', :colour =>  :mauve},
                   {:state => 'error_message', :colour =>  :redbrown},
                   {:state => 'user_withdrawn',  :colour => :pink} ]

        options = {:with => "impulses",
                   :linecolor => COLOURS[state_list[0][:colour]],
                   :linewidth => 4, :title => state_list[0][:state]}

        # here be database-specific dragons...
        # this uses a window function which is not supported by MySQL, but
        # is reportedly available in MariaDB from 10.2 onward (and Postgres 9.1+)

        sql = "SELECT DATE(created_at), COUNT(*), SUM(count(*)) " \
              "OVER (ORDER BY DATE(created_at)) " \
              "FROM info_requests " \
              "WHERE prominence != 'backpage' " \
              "GROUP BY DATE(created_at)"

        all_requests = select_as_columns(sql)

        # nothing to do, bail
        abort "warning: no request data to graph, skipping task" unless all_requests

        # start plotting the data from largest to smallest so
        # that the shorter bars overlay the taller bars

        plot_data_from_columns(all_requests, options, plot.data)

        graph_param_sets = []
        previous_states = []
        state_list.each_with_index do |state_info, index|
          if index > 0
            graph_param_sets << GraphParams.new(
              assemble_sql(state_exclusion_sql(previous_states)),
              options.merge({
                :title => state_info[:state],
                :linecolor => COLOURS[state_info[:colour]]})
            )
          end
          previous_states << state_list[index][:state]
        end

        plot_datasets(graph_param_sets, plot.data)

        # plot the cumulative counts
        options.merge!({
          :with => "lines",
          :linecolor => COLOURS[:lightgreen],
          :linewidth => 1,
          :title => "cumulative total number of requests",
          :using => "1:3",
          :axes => "x1y2",
        })
        plot_data_from_columns(all_requests, options, plot.data)
      end
    end
  end
end

