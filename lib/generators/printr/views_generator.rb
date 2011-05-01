module Printr
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../app/views",__FILE__)
      desc "Copies default printer templates to your application"
      argument :scope, :required => false, :default => nil,
               :desc => "the scope to copy views to."
      def copy_views
        directory "printr", "app/views/#{scope || :printr}"
      end
    end
  end
end
