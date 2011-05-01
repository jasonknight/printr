module Printr
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates",__FILE__)
      desc "Creates the printr initializer"
    
      def copy_initializer
        template "printr.rb", "config/initializers/printr.rb"
        copy_file "printrs.yml","config/printrs.yml"
      end
    end
  end
end
