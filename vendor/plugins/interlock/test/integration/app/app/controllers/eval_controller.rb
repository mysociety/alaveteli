class EvalController < ApplicationController

  def index
    render :text => eval(params['string']).inspect
  end
  
end
