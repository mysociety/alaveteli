=begin
  tools.rb - Utility functions

  Copyright (C) 2005-2008 Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'rbconfig'
if /mingw|mswin|mswin32/ =~ RUBY_PLATFORM
  ENV['PATH'] = %w(bin lib).collect{|dir|
    "#{Config::CONFIG["prefix"]}\\lib\\GTK\\#{dir};"
  }.join('') + ENV['PATH']
end

require 'gettext/tools/rgettext'
require 'gettext/tools/rmsgfmt'
require 'gettext/runtime/mofile'
require 'fileutils'

module GetText
  bindtextdomain "rgettext"

  BOM_UTF8 = [0xef, 0xbb, 0xbf].pack("c3")

  # Currently, GNU msgmerge doesn't accept BOM. 
  # This mesthod remove the UTF-8 BOM from the po-file.
  def remove_bom(path)  #:nodoc:
    bom = IO.read(path, 3)
    if bom == BOM_UTF8
      data = IO.read(path)[3..-1]
      File.open(path, "w") {|f| f.write(data)}
    end
  end

  # Merges two Uniforum style .po files together. 
  #
  # *Note* This function requires "msgmerge" tool included in GNU GetText. So you need to install GNU GetText. 
  #
  # The def.po file is an existing PO file with translations which will be taken 
  # over to the newly created file as long as they still match; comments will be preserved,
  # but extracted comments and file positions will be discarded. 
  #
  # The ref.pot file is the last created PO file with up-to-date source references but
  # old translations, or a PO Template file (generally created by rgettext);
  # any translations or comments in the file will be discarded, however dot
  # comments and file positions will be preserved.  Where an exact match
  # cannot be found, fuzzy matching is used to produce better results.
  #
  # Usually you don't need to call this function directly. Use GetText.update_pofiles instead.
  #
  # * defpo: a po-file. translations referring to old sources
  # * refpo: a po-file. references to new sources
  # * app_version: the application information which appears "Project-Id-Version: #{app_version}" in the pot/po-files.
  # * Returns: self 
  def msgmerge(defpo, refpo, app_version, options={})
    verbose = options.delete(:verbose)
    puts "msgmerge called" if verbose
    $stderr.print defpo + " "

    content = merge_po_files(defpo,refpo,options.delete(:msgmerge),verbose)
    
    if content.empty?
      # report failure
      failed_filename = refpo + "~"
      FileUtils.cp(refpo, failed_filename)
      $stderr.puts _("Failed to merge with %{defpo}") % {:defpo => defpo}
      $stderr.puts _("New .pot was copied to %{failed_filename}") %{:failed_filename => failed_filename}
      raise _("Check these po/pot-files. It may have syntax errors or something wrong.")
    else
      # update version and save merged data
      content.sub!(/(Project-Id-Version\:).*$/, "\\1 #{app_version}\\n\"")
      File.open(defpo, "w") {|f|f.write(content)}
    end
    
    self
  end

  # Creates mo-files using #{po_root}/#{lang}/*.po an put them to 
  # #{targetdir}/#{targetdir_rule}/. 
  #
  # This is a convenience function of GetText.rmsgfmt for multiple target files.
  # * options: options as a Hash.
  #   * verbose: true if verbose mode, otherwise false
  #   * po_root: the root directory of po-files.
  #   * mo_root: the target root directory where the mo-files are stored.
  #   * mo_path_rule: the target directory for each mo-files.
  def create_mofiles(options = {})
    options = {:po_root => "./po"}.merge(options)

    Dir.glob(File.join(options[:po_root], "*/*.po")) do |po_file|
      mo_file = mo_file_from_po_file(po_file,options)
      $stderr.print %Q[#{po_file} -> #{mo_file} ... ] if options[:verbose]
      FileUtils.mkdir_p(File.dirname(mo_file))
      rmsgfmt(po_file, mo_file)
      $stderr.puts "Done." if options[:verbose]
    end
  end


  # At first, this creates the #{po_root}/#{domainname}.pot file using GetText.rgettext.
  # In the second step, this updates(merges) the #{po_root}/#{domainname}.pot and all of the
  # #{po_root}/#{lang}/#{domainname}.po files under "po_root" using "msgmerge". 
  #
  # *Note* "msgmerge" tool is included in GNU GetText. So you need to install GNU GetText. 
  #
  # See <HOWTO maintain po/mo files(http://www.yotabanana.com/hiki/ruby-gettext-howto-manage.html)> for more detals.
  # * domainname: the textdomain name.
  # * targetfiles: An Array of target files, that should be parsed for messages (See GetText.rgettext for more details).
  # * app_version: the application information which appears "Project-Id-Version: #{app_version}" in the pot/po-files.
  # * options: a hash with following possible settings
  #     :lang    - update files only for one language - the language specified by this option
  #     :po_root - the root directory of po-files
  #     :msgmerge - an array with the options, passed through to the gnu msgmerge tool
  #                 symbols are automatically translated to options with dashes,
  #                 example: [:no_wrap, :no_fuzzy_matching, :sort_output] translated to '--no-fuzzy-matching --sort-output'
  #     :verbose - true to show verbose messages. default is false.
  #
  # Example: GetText.update_pofiles("myapp", Dir.glob("lib/*.rb"), "myapp 1.0.0", :verbose => true)
  def update_pofiles(textdomain, files, app_version, options = {})
    puts options.inspect if options[:verbose]

    #write found messages to tmp.pot
    temp_pot = "tmp.pot"
    rgettext(files, temp_pot)

    #merge tmp.pot and existing pot
    po_root = options.delete(:po_root) || "po"
    FileUtils.mkdir_p(po_root)
    msgmerge("#{po_root}/#{textdomain}.pot", temp_pot, app_version, options.dup)

    #update local po-files
    only_one_language = options.delete(:lang)
    if only_one_language
      msgmerge("#{po_root}/#{only_one_language}/#{textdomain}.po", temp_pot, app_version, options.dup)
    else
      Dir.glob("#{po_root}/*/#{textdomain}.po") do |po_file|
        msgmerge(po_file, temp_pot, app_version, options.dup)
      end
    end

    File.delete(temp_pot)
  end

  private

  # Merge 2 po files, using msgmerge
  def merge_po_files(po_a,po_b,msgmerge_options=[],verbose=false)
    return File.read(po_b) unless FileTest.exist? po_a

    cmd = ENV["MSGMERGE_PATH"] || "msgmerge"
    ensure_command_exists(cmd)

    remove_bom(po_a)

    cmd_params = array_to_cli_options(msgmerge_options)
    to_run = "#{cmd} #{cmd_params} #{po_a} #{po_b}"
    puts "\nrunning #{to_run}" if verbose
    `#{to_run}`
  end

  # convert an array of String/Symbol to cli options
  def array_to_cli_options(array)
    [*array].map do |o|
      o.kind_of?(Symbol) ? "--#{o}".gsub('_','-') : o.to_s
    end.join(' ')
  end

  def ensure_command_exists(cmd)
    `#{cmd} --help`
    unless $? && $?.success?
      raise _("`%{cmd}' can not be found. \nInstall GNU Gettext then set PATH or MSGMERGE_PATH correctly.") % {:cmd => cmd}
    end
  end

  # where lies the mo file for a given po_file
  # generare directory unless it exists
  def mo_file_from_po_file(po_file,options)
    options = {
      :mo_root => "./data/locale",
      :mo_path_rule => "%{lang}/LC_MESSAGES"
    }.merge(options)
    
    lang, textdomain = %r[/([^/]+?)/(.*)\.po].match(po_file[options[:po_root].size..-1]).to_a[1,2]

    mo_dir_rule = File.join(options[:mo_root], options[:mo_path_rule])
    mo_dir = mo_dir_rule % {:lang => lang}
    File.join(mo_dir, "#{textdomain}.mo")
  end
end

if __FILE__ == $0
  GetText.update_pofiles("foo", ARGV, "foo 1.1.0")
end
