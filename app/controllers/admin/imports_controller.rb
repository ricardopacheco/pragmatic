# frozen_string_literal: true

module Admin
  class ImportsController < BaseController
    def index
      @form = CreateImportForm.new
      @imports = ImportDecorator.wrap(Import.latest)
      @presenter = presenter_class.new(view_context, Current.user, imports: @imports)
    end

    def show
      @import = ImportDecorator.new(Import.find(params[:id]))
      @presenter = presenter_class.new(view_context, Current.user, import: @import)
    end

    def create
      @form = CreateImportForm.new(import_params)

      if @form.submit(Current.user.id)
        redirect_to admin_import_path(@form.import), notice: t(".success")
      else
        @imports = ImportDecorator.wrap(Import.latest)
        @presenter = presenter_class.new(view_context, Current.user, imports: @imports)

        render :index, status: :unprocessable_content
      end
    end

    private

    def import_params
      params.expect(import: [:spreadsheet])
    end
  end
end
