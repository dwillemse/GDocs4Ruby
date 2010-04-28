Gem::Specification.new do |s|
   s.name = %q{gdocs4ruby}
   s.version = "0.1.0"
   s.date = %q{2010-03-12}
   s.authors = ["Mike Reich"]
   s.email = %q{mike@seabourneconsulting.com}
   s.summary = %q{A full featured wrapper for interacting with the Google Docs API}
   s.homepage = %q{http://gdocs4ruby.rubyforge.org/}
   s.description = %q{A full featured wrapper for interacting with the Google Docs API}
   s.files = ["README", "CHANGELOG", "lib/gdocs4ruby.rb", "lib/gdocs4ruby/service.rb", "lib/gdocs4ruby/folder.rb", "lib/gdocs4ruby/document.rb", "lib/gdocs4ruby/base_object.rb", "lib/gdocs4ruby/spreadsheet.rb", "lib/gdocs4ruby/presentation.rb"]
   s.rubyforge_project = 'gdocs4ruby'
   s.has_rdoc = true
   s.test_files = ['test/unit.rb'] 
   s.add_dependency('gdata4ruby', '>= 0.1.0')
end 
