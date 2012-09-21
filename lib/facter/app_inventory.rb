require 'rexml/document'
include REXML

# Thanks to Marcus https://github.com/DrMegahertz/ for helping out!

def parse(element)
  case element.name
  when 'array'
    element.elements.map {|child| parse(child)}

  when 'dict'
    result = {}

    element.elements.each_slice(2) do |key, value|
      result[key.text] = parse(value)
    end

    result

  when 'real'
    element.text.to_f

  when 'integer'
    element.text.to_i

  when 'string', 'date'
    element.text

  else
    # FIXME: Remove me or beef me up
    # puts "Unknown type " + element.name
  end
end

begin
  xml = Facter::Util::Resolution.exec('system_profiler SPApplicationsDataType -xml')
  xmldoc = Document.new(xml)
  result = parse(xmldoc.root[1])
rescue
  result = ''
end

begin
  apps = []

  result[0]['_items'].each do |application|

    # Remove all spaces and convert app name to lowercase
    app_name = application['_name'].downcase.gsub(' ','')

    # Only list applications in /Applications, Skip /Application/Utilities
    if application['path'].match(/^\/Applications/) and application['path'].index('Utilities') == nil
      if !application['version'].nil?

        Facter.add('app_' + app_name + '_version') { setcode { application['version'] } }
        Facter.add('app_' + app_name) { setcode { true } }

        apps << app_name
      end
    end
  end

  # Create apps fact with all applications separated by comma
  Facter.add('apps') { setcode { apps.join ',' } }

rescue
end
