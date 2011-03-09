# coding: utf-8
require File.expand_path("../spec_helper", File.dirname(__FILE__))

FastGettext.silence_errors

ActiveRecord::Base.establish_connection({
  :adapter => "sqlite3",
  :database => ":memory:",
})

ActiveRecord::Schema.define(:version => 1) do
  create_table :car_seats, :force=>true do |t|
    t.string :seat_color
  end

  create_table :parts, :force=>true do |t|
    t.string :name
    t.references :car_seat
  end
end

class CarSeat < ActiveRecord::Base
  validates_presence_of :seat_color, :message=>"translate me"
  has_many :parts
  accepts_nested_attributes_for :parts
end

class Part < ActiveRecord::Base
  belongs_to :car_seat
end

describe ActiveRecord::Base do
  before do
    FastGettext.current_cache = {}
  end

  describe :human_name do
    it "is translated through FastGettext" do
      CarSeat.should_receive(:_).with('car seat').and_return('Autositz')
      CarSeat.human_name.should == 'Autositz'
    end
  end

  describe :human_attribute_name do
    it "translates attributes through FastGettext" do
      CarSeat.should_receive(:s_).with('CarSeat|Seat color').and_return('Sitz farbe')
      CarSeat.human_attribute_name(:seat_color).should == 'Sitz farbe'
    end

    it "translates nested attributes through FastGettext" do
      CarSeat.should_receive(:s_).with('CarSeat|Parts|Name').and_return('Handle')
      CarSeat.human_attribute_name(:"parts.name").should == 'Handle'
    end
  end

  describe 'error messages' do
    let(:model){
      c = CarSeat.new
      c.valid?
      c
    }

    it "translates error messages" do
      FastGettext.stub!(:current_repository).and_return('translate me'=>"Übersetz mich!")
      FastGettext._('translate me').should == "Übersetz mich!"
      model.errors.on(:seat_color).should == "Übersetz mich!"
    end

    it "translates scoped error messages" do
      pending 'scope is no longer added in 3.x' if ActiveRecord::VERSION::MAJOR >= 3
      FastGettext.stub!(:current_repository).and_return('activerecord.errors.translate me'=>"Übersetz mich!")
      FastGettext._('activerecord.errors.translate me').should == "Übersetz mich!"
      model.errors.on(:seat_color).should == "Übersetz mich!"
    end

    it "translates error messages with %{fn}" do
      pending
      FastGettext.stub!(:current_repository).and_return('translate me'=>"Übersetz %{fn} mich!")
      FastGettext._('translate me').should == "Übersetz %{fn} mich!"
      model.errors.on(:seat_color).should == "Übersetz car_seat mich!"
    end
  end
end
