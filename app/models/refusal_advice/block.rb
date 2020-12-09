require 'ostruct'

##
# A superclass for question, actions and suggestions that are presented to users
# to help them challenge refusals.
#
class RefusalAdvice::Block
  def initialize(data)
    @data = data
  end

  def id
    data[:id]
  end

  def label
    renderable_object(data[:label])
  end

  def show_if
    data[:show_if]
  end

  def ==(other)
    data == other.data
  end

  protected

  attr_reader :data

  private

  def collection(value)
    Array(value).map(&method(:object))
  end

  def object(value)
    OpenStruct.new(value) if value
  end

  def renderable_object(value)
    return unless value

    params = ActionController::Parameters.new(value).permit(
      :partial, :plain, :html
    )
    params[:html] = params[:html].html_safe if params[:html]
    params.to_h
  end
end
