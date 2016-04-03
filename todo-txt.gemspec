Gem::Specification.new do |s|
  s.name = 'todo-txt'
  s.version = '0.6'
  s.authors = ['Sam Rose']
  s.email = 'samwho@lbak.co.uk'
  s.summary = 'A client library for parsing todo.txt files.'
  s.homepage = 'http://github.com/samwho/todo-txt-gem'
  s.description = 'Allows for simple parsing of todo.txt files, as ' \
    'per Gina Trapani\'s todo.txt project.'
  s.required_ruby_version = '>= 1.8.7'
  s.license = 'GPL-2'

  # Add all files to the files parameter.
  s.files = `git ls-files`.split(/\n/)
end
