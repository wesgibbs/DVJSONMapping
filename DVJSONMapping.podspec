Pod::Spec.new do |s|
  s.name         = "DVJSONMapping"
  s.version      = "0.0.1"
  s.summary      = "A library for mapping JSON-to-CoreData and CoreData-to-JSON."
  s.homepage     = "http://github/peymano/DVJSONMapping"
  s.license      = 'Apache 2.0'
  s.author       = { "Peyman Oreizy" => "peymano@dynamicvariable.com" }
  s.source       = { :git => "http://github.com/peymano/DVJSONMapping.git", :tag => "0.0.1" }
  s.platform     = :ios, '5.0'
  s.source_files = 'DVJSONMapping'
  s.framework    = 'CoreData'
  s.requires_arc = true
  s.dependency 'DVCoreDataFinders', '~> 0.3'
end
