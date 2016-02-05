Pod::Spec.new do |s|
  s.name             = "CoreDataDandy"
  s.version          = "0.2.4"
  s.summary          = "A feature-light wrapper around Core Data that simplifies common database operations."
  s.description      = "Initializes your Core Data stack, manages your saves, inserts, and fetches, and maps json to NSManagedObjects."
  s.homepage         = "https://github.com/fuzz-productions/CoreDataDandy"
  s.license          = 'MIT'
  s.author           = { "Noah Blake" => "noah@fuzzproductions.com" }
  s.source           = { :git => "https://github.com/fuzz-productions/CoreDataDandy.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/fuzzpro'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Source/*.swift',
    'Source/Core/*.swift',
    'Source/Extensions/*.swift',
    'Source/Value\ Conversion/*.swift',

  s.frameworks = 'CoreData'
end