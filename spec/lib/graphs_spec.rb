# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/graphs')

describe Graphs do

  let(:dummy_class) { Class.new { extend Graphs } }

  describe "when asked to select data as columns" do

    let(:user1) { FactoryGirl.create(:user) }
    let(:user2) { FactoryGirl.create(:user) }

    it "returns an array containing arrays of column values" do
      sql = "SELECT name, id FROM users where id IN (#{user1.id}, #{user2.id}) " \
            "ORDER BY id"
      result = dummy_class.select_as_columns(sql)
      expect(result).to eq [[user1.name, user2.name], [user1.id.to_s, user2.id.to_s]]
    end

    it "returns an array containing single value arrays if there is a single result row" do
      sql = "SELECT name, id FROM users where id = #{user1.id}"
      result = dummy_class.select_as_columns(sql)
      expect(result).to eq [[user1.name], [user1.id.to_s]]
    end

    it "returns nil if there are no results" do
      sql = "SELECT name, id FROM users WHERE 1=0"
      expect(dummy_class.select_as_columns(sql)).to be_nil
    end

    it "raises an error if there is a mistake in the SQL statement" do
      sql = "SELECT * FROM there_is_no_table_here"
      expect {dummy_class.select_as_columns(sql)}.
        to raise_error(ActiveRecord::StatementInvalid)
    end

  end

  describe "when asked to create a plottable dataset" do

    let(:test_data) { [["title 1", "title 2"], [42, 15], [42, 57]] }

    it "returns a Gnuplot::DataSet object" do
      expect(dummy_class.create_dataset(test_data, {})).
        to be_a(Gnuplot::DataSet)
    end

    it "uses the first 2 columns by default" do
      result = dummy_class.create_dataset(test_data, {})
      expect(result.using).to eq "1:2"
    end

    it "uses the supplied column references via the 'using' option" do
      result = dummy_class.create_dataset(test_data, {:using => "1:3"})
      expect(result.using).to eq "1:3"
    end

    it "sets the key title" do
      result = dummy_class.create_dataset(test_data, {:title => "Dataset Title"})
      expect(result.title).to eq "Dataset Title"
    end

    it "sets the plot type for the dataset via the 'with' option" do
      result = dummy_class.create_dataset(test_data, {:with => "lines"})
      expect(result.with).to eq "lines"
    end

    it "sets the line colour via the 'linecolor' option" do
      result = dummy_class.create_dataset(test_data, {:linecolor => 2})
      expect(result.linecolor).to eq 2
    end

    it "sets the line width via the 'linewidth' option" do
      result = dummy_class.create_dataset(test_data, {:linewidth => 10})
      expect(result.linewidth).to eq 10
    end

    it "sets the axes width via the 'axes' option" do
      result = dummy_class.create_dataset(test_data, {:axes => "x1y1"})
      expect(result.axes).to eq "x1y1"
    end
  end

  describe "when asked to plot data from sql" do

    let(:sql) { "SELECT name, id FROM users WHERE 1=0" }
    let(:test_data) { [["title 1", "title 2"], [42, 15], [42, 57]] }

    it "calls select_as_columns with the provided SQL" do
      expect(dummy_class).to receive(:select_as_columns).with(sql) { nil }
      dummy_class.plot_data_from_sql(sql, {}, [])
    end

    it "does not call create_dataset if select_as_columns returns no data" do
      allow(dummy_class).to receive(:select_as_columns).with(sql) { nil }
      expect(dummy_class).not_to receive(:create_dataset)
      dummy_class.plot_data_from_sql(sql, {}, [])
    end

    context "select_as_columns returns data" do

      it "calls create_dataset" do
        allow(dummy_class).to receive(:select_as_columns).with(sql) { test_data }
        expect(dummy_class).to receive(:create_dataset).with(test_data, {})
        dummy_class.plot_data_from_sql(sql, {}, [])
      end

      it "appends the created dataset to the supplied datasets collection" do
        datasets = []
        mock_dataset = double(Gnuplot::DataSet)
        allow(dummy_class).to receive(:select_as_columns).with(sql) { test_data }
        allow(dummy_class).to receive(:create_dataset).with(test_data, {}) { mock_dataset }
        dummy_class.plot_data_from_sql(sql, {}, datasets)
        expect(datasets).to eq [mock_dataset]
      end

    end

  end

  describe "when asked to plot data from columns" do

    let(:test_data) { [["title 1", "title 2"], [42, 15], [42, 57]] }

    it "calls create_dataset with the supplied data" do
      expect(dummy_class).to receive(:create_dataset).with(test_data, {})
      dummy_class.plot_data_from_columns(test_data, {}, [])
    end

    it "appends the created dataset to the supplied datasets collection" do
      datasets = []
      mock_dataset = double(Gnuplot::DataSet)
      allow(dummy_class).to receive(:create_dataset).with(test_data, {}) { mock_dataset }
      dummy_class.plot_data_from_columns(test_data, {}, datasets)
      expect(datasets).to eq [mock_dataset]
    end

    # odd but possible as the calling code may not have checked
    it "does not call create_dataset if the supplied data is null" do
      expect(dummy_class).not_to receive(:create_dataset)
      dummy_class.plot_data_from_columns(nil, {}, [])
    end

  end

  describe "when asked to plot multiple datasets" do
    include Graphs

    let(:graph_def_1) do
      Graphs::GraphParams.new(
        "SELECT DATE(created_at), COUNT(*) FROM users GROUP BY DATE(created_at)",
        { :title => "test 1",
          :with => "lines",
          :linecolor => Graphs::COLOURS[:mauve] }
      )
    end

    let(:graph_def_2) do
      Graphs::GraphParams.new(
        "SELECT DATE(created_at), COUNT(*) FROM info_requests GROUP BY DATE(created_at)",
        { :title => "test 2",
          :with => "lines",
          :linecolor => Graphs::COLOURS[:red] }
      )
     end

    it "passes the sql and options for a set of params to plot_data_from_sql" do
      expect(dummy_class).to receive(:plot_data_from_sql).
        with(
          graph_def_1.sql,
          graph_def_1.options,
          []
        )
      dummy_class.plot_datasets([graph_def_1], [])
    end

    it "calls plot_data_from_sql for each set of data supplied" do
      graph_param_sets = [graph_def_1, graph_def_2]
      expect(dummy_class).to receive(:plot_data_from_sql).exactly(2).times
      dummy_class.plot_datasets(graph_param_sets, [])
    end

  end

end
