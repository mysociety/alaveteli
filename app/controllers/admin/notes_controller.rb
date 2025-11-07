class Admin::NotesController < AdminController
  include Admin::TagHelper
  include TranslatableParams

  def new
    @note = scope.build
    @note.build_all_translations
  end

  def create
    @note = scope.build(note_params)
    if @note.save
      notice = 'Note successfully created.'
      redirect_to admin_note_parent_path(@note), notice: notice
    else
      @note.build_all_translations
      render :new
    end
  end

  def edit
    @note = scope.find(params[:id])
    @note.build_all_translations
  end

  def update
    @note = scope.find(params[:id])
    if @note.update(note_params)
      notice = 'Note successfully updated.'
      redirect_to admin_note_parent_path(@note), notice: notice
    else
      @note.build_all_translations
      render :edit
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @note.destroy
    notice = 'Note successfully destroyed.'
    redirect_to admin_note_parent_path(@note), notice: notice
  end

  private

  def scope
    Note.where(params.slice(:notable_tag, :notable_id, :notable_type).permit!)
  end

  def note_params
    translatable_params(
      params.require(:note),
      translated_keys: [:locale, :body],
      general_keys: [:notable_tag, :notable_id, :notable_type]
    )
  end
end
