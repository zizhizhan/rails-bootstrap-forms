require_relative 'helpers/nested_form'

module BootstrapForm
  module Helper
    include ::BootstrapForm::Helpers::NestedForm

    def bootstrap_form_with(model: nil, scope: nil, url: nil, format: nil, **options)
      options[:allow_method_names_outside_object] = true
      options[:skip_default_ids] = true
      options.reverse_merge!({builder: BootstrapForm::FormBuilder})

      if model
        url ||= polymorphic_path(model, format: format)

        model   = model.last if model.is_a?(Array)
        scope ||= model_name_from_record_or_class(model).param_key
      end

      if block_given?
        builder = instantiate_builder(scope, model, options)
        output  = capture(builder, &Proc.new)
        options[:multipart] ||= builder.multipart?

        html_options = html_options_for_form_with(url, model, options)
        form_tag_with_body(html_options, output)
      else
        html_options = html_options_for_form_with(url, model, options)
        form_tag_html(html_options)
      end
    end

    def __form_for(record, options = {}, &block)
      raise ArgumentError, "Missing block" unless block_given?
      html_options = options[:html] ||= {}

      case record
      when String, Symbol
        object_name = record
        object      = nil
      else
        object      = record.is_a?(Array) ? record.last : record
        raise ArgumentError, "First argument in form cannot contain nil or be empty" unless object
        object_name = options[:as] || model_name_from_record_or_class(object).param_key
        apply_form_for_options!(record, object, options)
      end

      html_options[:data]   = options.delete(:data)   if options.has_key?(:data)
      html_options[:remote] = options.delete(:remote) if options.has_key?(:remote)
      html_options[:method] = options.delete(:method) if options.has_key?(:method)
      html_options[:enforce_utf8] = options.delete(:enforce_utf8) if options.has_key?(:enforce_utf8)
      html_options[:authenticity_token] = options.delete(:authenticity_token)

      builder = instantiate_builder(object_name, object, options)
      output  = capture(builder, &block)
      html_options[:multipart] ||= builder.multipart?

      html_options = html_options_for_form(options[:url] || {}, html_options)
      form_tag_with_body(html_options, output)
    end

    def bootstrap_form_for(object, options = {}, &block)
      options.reverse_merge!({builder: BootstrapForm::FormBuilder})

      options[:html] ||= {}
      options[:html][:role] ||= 'form'

      layout = case options[:layout]
        when :inline
          "form-inline"
        when :horizontal
          "form-horizontal"
      end

      if layout
        options[:html][:class] = [options[:html][:class], layout].compact.join(" ")
      end

      temporarily_disable_field_error_proc do
        form_for(object, options, &block)
      end
    end

    def bootstrap_form_tag(options = {}, &block)
      options[:acts_like_form_tag] = true

      bootstrap_form_for("", options, &block)
    end

    def temporarily_disable_field_error_proc
      original_proc = ActionView::Base.field_error_proc
      ActionView::Base.field_error_proc = proc { |input, instance| input }
      yield
    ensure
      ActionView::Base.field_error_proc = original_proc
    end
  end
end
