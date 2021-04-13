module UserHelper
    def survey_form(survey)
        concat %(<form method="post" action="#{h survey.survey_url}">\n).html_safe
        survey.required_params.each do |k, v|
            concat %(    <input type="hidden" name="#{h k}" value="#{h v}">\n).html_safe
        end
        concat %(    <input type="hidden" name="return_url" value="#{h request.url}">\n).html_safe
        yield
        concat %(    <input type="submit">).html_safe
        concat %(</form>\n).html_safe
    end
end
