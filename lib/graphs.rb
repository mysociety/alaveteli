# -*- encoding : utf-8 -*-
require 'gnuplot'

module Graphs

  # the colour references given here are for the default palette
  # as provided by our basic gnuplot configuration, do not rely on them
  # if you have altered the gnuplot install
  COLOURS = {
    :darkblue => 8,
    :lightblue => 3,
    :yellow => 9,
    :red => 6,
    :lightgreen => 2,
    :darkgreen => 10,
    :cyan => 5,
    :darkyellow => 7,
    :mauve => 4,
    :redbrown => 12, # previously "darky reddy brown"
    :pink => 13,
    :bluemauve => 11,
    :limegreen => 14
  }.freeze
  COLORS = COLOURS

  GraphParams = Struct.new(:sql, :options)

  # return the results from the SQL statement in the format:
  #   [[row1_column1, row2_column1], [row1_column2, row2, column2]]
  # or nil if there are no results found
  # errors not caught so will be sent to the command line
  def select_as_columns(sql)
    hash_array = User.connection.select_all(sql)
    return if hash_array.empty?
    columns = hash_array.first.values.map { |val| [val] }
    if hash_array.size > 1
      hash_array[1..-1].each do |result|
        result.values.each.with_index do |value, i|
          columns[i] << value
        end
      end
    end
    columns
  end

  # accepts column format data (see above) and a hash of gnuplot options
  # for outputting the graph
  # returns the resulting Gnuplot::DataSet
  def create_dataset(data, options)
    default = {:using => "1:2"} #in most cases, we just want the first 2 columns
    options = default.merge(options)
    Gnuplot::DataSet.new(data) do |ds|
      options.keys.each do |option|
        ds.send("#{option}=", options[option])
       end
    end
  end

  # helper method to append a new dataset to the current graph by passing in
  # a sql statement
  def plot_data_from_sql(sql, options, graph_datasets)
    data = select_as_columns(sql)
    graph_datasets << create_dataset(data, options) if data
  end

  # helper method to append a new dataset to the current graph by passing in
  # prefetched column formatted data (useful where data is reused)
  def plot_data_from_columns(columns, options, graph_datasets)
    graph_datasets << create_dataset(columns, options) if columns
  end

  def plot_datasets(graph_param_sets, graph_datasets)
    graph_param_sets.each do |params|
      plot_data_from_sql(params.sql, params.options, graph_datasets)
    end
  end
end
