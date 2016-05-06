# -*- encoding : utf-8 -*-
module AlaveteliGetText
  class FuzzyCleaner
    def clean_po(input)
      lines = input.split("\n")

      lines.each_with_index do |line, index|
        match = /^msgid "(.*)"/.match(line)
        if $1
          if /^#, fuzzy/.match(lines[index-1])
            # one line msgstr
            if /^msgstr "(.+)"/.match(lines[index+1])
             lines[index+1] = "msgstr \"\""
              lines.delete_at(index-1)
            end
            # multiline msgstr
            if /^msgstr ""/.match(lines[index+1])
              while /^".+"/.match(lines[index+2])
                lines.delete_at(index+2)
              end
              lines.delete_at(index-1)
            end
            # plural msgstr
            if /^msgid_plural "(.*)"/.match(lines[index+1])
              offset = 0
              while /^msgstr\[#{offset}\] "(.*)"/.match(lines[index+2+offset])
                lines[index+2+offset] = "msgstr[#{offset}] \"\""
                offset += 1
              end
              lines.delete_at(index-1)
            end
          end
        end
      end

      lines.join("\n") << "\n"
    end
  end
end
