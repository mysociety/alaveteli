class FrontpageController < ApplicationController
    layout "default"

    def index
        respond_to do |format|
            format.html
        end
    end
end

