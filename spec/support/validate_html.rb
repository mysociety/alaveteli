# Validate an entire HTML page
def validate_html(html)
    $tempfilecount = $tempfilecount + 1
    tempfilename = File.join(Dir::tmpdir, "railshtmlvalidate."+$$.to_s+"."+$tempfilecount.to_s+".html")
    File.open(tempfilename, "w+") do |f|
        f.puts html
    end
    if not system($html_validation_script, *($html_validation_script_options +[tempfilename]))
        raise "HTML validation error in " + tempfilename + " HTTP status: " + @response.response_code.to_s
    end
    File.unlink(tempfilename)
    return true
end

# Validate HTML fragment by wrapping it as the <body> of a page
def validate_as_body(html)
    validate_html('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">' +
        "<html><head><title>Test</title></head><body>#{html}</body></html>")
end

# Monkeypatch! Validate HTML in tests.
$html_validation_script_found = false
Configuration::utility_search_path.each do |d|
    $html_validation_script = File.join(d, "validate")
    $html_validation_script_options = ["--charset=utf-8"]
    if File.file? $html_validation_script and File.executable? $html_validation_script
        $html_validation_script_found = true
        break
    end
end
if $tempfilecount.nil?
    $tempfilecount = 0
    if $html_validation_script_found
        module ActionController
            class TestCase
                module Behavior
                    # Hook into the process function, so can automatically get HTML after each request
                    alias :original_process :process
                    def is_fragment
                        # XXX there must be a better way of doing this!
                        return @request.query_parameters["action"] == "search_typeahead"
                    end
                    def process(action, parameters = nil, session = nil, flash = nil, http_method = 'GET')
                        self.original_process(action, parameters, session, flash, http_method)
                        # don't validate auto-generated HTML
                        return if @request.query_parameters["action"] == "get_attachment_as_html"
                        # XXX Is there a better way to check this than calling a private method?
                        return unless @response.template.controller.instance_eval { render_views? }
                        # And then if HTML, not a redirect (302, 301)
                        if @response.content_type == "text/html" && ! [301,302,401].include?(@response.response_code)
                        if !is_fragment
                            validate_html(@response.body)
                        else
                            # it's a partial
                            validate_as_body(@response.body)
                        end
                        end
                    end
                end
            end
        end
    else
        puts "WARNING: HTML validation script " + $html_validation_script + " not found"
    end
end
