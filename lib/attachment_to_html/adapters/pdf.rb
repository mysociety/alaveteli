module AttachmentToHTML
    module Adapters
        class Pdf < Base

            def initialize(args)
                @tempdir = args[:tempdir]
                super(args)
            end

            def title
                @title
            end

            def body
                convert @body
            end

            private

            def convert(text)
                Dir.chdir(@tempdir) do
                    if RUBY_VERSION.to_f >= 1.9
                        tempfile = Tempfile.new('foiextract', '.',  :encoding => text.encoding)
                    else
                        tempfile = Tempfile.new('foiextract', '.')
                    end
                    tempfile.print text
                    tempfile.flush

                    # We set a timeout here, because pdftohtml
                    # can spiral out of control on some PDF files and we don't
                    # want to crash the whole server.
                    html = AlaveteliExternalCommand.run(
                             "pdftohtml",
                             "-nodrm",
                             "-zoom",
                             "1.0",
                             "-stdout",
                             "-enc",
                             "UTF-8",
                             "-noframes",
                             tempfile.path,
                             :timeout => 30
                    )

                    tempfile.close
                    tempfile.delete

                    html
               end
           end

        end
    end
end
