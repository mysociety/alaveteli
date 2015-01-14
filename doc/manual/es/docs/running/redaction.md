---
layout: es/page
title: Edición de información delicada
---

# Edición de información delicada

En algunos países los requisitos locales exigen que las solicitudes contengan datos personales, tales como la dirección o el número del documento de indentidad de la persona que solicita la información. Normalmente los solicitantes no desean que esta información se muestre de forma pública.

Alaveteli tiene cierta habilidad para gestionar estos datos mediante el uso de <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">normas de censura</a>.

El [tema](https://github.com/mysociety/derechoapreguntar-theme) que utilizaremos como ejemplo requiere el número del documento nacional de identidad y lo que se conoce como ley general en Nicaragua (fecha de nacimiento, domicilio, profesión y estado civil).

![Formulario de registro con detalles adicionales]({{ site.baseurl }}assets/img/redaction-sign-up-form.png)

## Número del documento de identidad

Empezaremos mirando el número del documento nacional de identidad. Este un buen ejemplo de un concepto cuya edición resulta sencilla. Es único para cada usuario y cuenta con un formato específico comprobable.

Para enviar el número del documento de identidad a la autoridad, sobrescribiremos [la plantilla inicial de solicitud](https://github.com/mysociety/alaveteli/blob/master/app/views/outgoing_mailer/initial_request.text.erb) (fragmento de código recortado):

    <%= raw @outgoing_message.body.strip %>

    -------------------------------------------------------------------

    <%= _('Requestor details') %>
    <%= _('Identity Card Number') %>: <%= @user_identity_card_number %>

Ahora, al efectuar una solicitud, se añade el número del documento de identidad del usuario al pie del correo saliente.

![Mensaje saliente con el número del documento de identidad]({{ site.baseurl }}assets/img/redaction-outgoing-message-with-id-number.png)

En este punto no hemos añadido ninguna <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a>. Cuando la autoridad responde es poco probable que elimine el texto citado del correo electrónico:

![Número del documento de identidad en el texto citado]({{ site.baseurl }}assets/img/redaction-id-number-in-quoted-section.png)

Podríamos añadir una <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a> para la solicitud individual pero, ya que cada solicitud incluirá un número de documento de identidad, es mejor añadir algo de código para que se edite automáticamente.

Para ilustrar este ejemplo, aplicaremos un parche al modelo `User` con una retrollamada que crea una <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a> cuando se crea o actualiza un usuario.

    # THEME_ROOT/lib/model_patches.rb
    User.class_eval do
      after_save :update_censor_rules

      private

      def update_censor_rules
        censor_rules.where(:text => identity_card_number).first_or_create(
          :text => identity_card_number,
          :replacement => _('REDACTED'),
          :last_edit_editor => THEME_NAME,
          :last_edit_comment => _('Updated automatically after_save')
        )
      end
    end

Puede ver la nueva <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a> en la interfaz de administración:

![Norma de censura añadida automáticamente]({{ site.baseurl }}assets/img/redaction-automatically-added-id-number-censor-rule.png)

Ahora el número del documento de identidad se edita:

![Número del documento de identidad editado automáticamente]({{ site.baseurl }}assets/img/redaction-id-number-redacted.png)

También se edita si el organismo público utiliza el número del documento de identidad en el cuerpo del correo:

![Número del documento de identidad editado en el cuerpo principal]({{ site.baseurl }}assets/img/redaction-id-number-in-main-body-redacted.png)

Una <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a> añadida a un usuario solo se aplica en la correspondencia de solicitudes creadas por dicho usuario. No se aplica a anotaciones realizadas por el usuario.

**Advertencia:** La edición de este tipo requiere que el texto delicado se encuentre exactamente en el mismo formato que la <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a>. Si es mínimamente diferente, es posible que la edición falle. Si el organismo público eliminase los guiones del número, este no se editaría:

![Número del documento de identidad no editado en el cuerpo principal]({{ site.baseurl }}assets/img/redaction-id-number-in-main-body-not-redacted.png)

**Advertencia:** Alaveteli también intenta editar el texto de todos los adjuntos. Solo puede hacerlo si detecta la cadena de texto exacta, que no suele ser posible con formatos binarios como PDF o Word.

Alaveteli puede normalmente editar la información delicada al convertir un documento de texto o en formato PDF a HTML:

![Edición de PDF a HTML]({{ site.baseurl }}assets/img/redaction-pdf-redaction-as-html.png)

Este PDF no contiene la cadena de texto en el formato binario, así que la edición _no_ se aplica al descargar el documento PDF original:

![Descarga del PDF original]({{ site.baseurl }}assets/img/redaction-pdf-redaction-download.png)

## Ley general

La información de la ley general es mucho más difícil de editar automáticamente. No está tan estructurada y es poco probable que sea única (por ejemplo, domicilio: Londres).

Añadiremos la información de la ley general a la [plantilla inicial de solicitud](https://github.com/mysociety/alaveteli/blob/master/app/views/outgoing_mailer/initial_request.text.erb) del mismo modo que el número del documento de identidad:

    <%= _('Requestor details') %>:
    <%-# !!!IF YOU CHANGE THE FORMAT OF THE BLOCK BELOW, ADD A NEW CENSOR RULE!!! -%>
    ===================================================================
    # <%= _('Name') %>: <%= @user_name %>
    # <%= _('Identity Card Number') %>: <%= @user_identity_card_number %>
    <% @user_general_law_attributes.each do |key, value| %>
    # <%= _(key.humanize) %>: <%= value %>
    <% end %>
    ===================================================================

Ahora la información está contenida en un bloque de texto con un formato especial.

![Mensaje saliente con la ley general]({{ site.baseurl }}assets/img/redaction-outgoing-message-with-general-law.png)

Así se permite que una <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a> concuerde con el formato especial y elimine todo lo que se halle en su interior. Esta <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a> es general, así que actuará en las coincidencias de todas las solicitudes.

     # THEME_ROOT/lib/censor_rules.rb
    # If not already created, make a CensorRule that hides personal information
    regexp = '={67}\s*\n(?:[^\n]*?#[^\n]*?: ?[^\n]*\n){3,10}[^\n]*={67}'

    unless CensorRule.find_by_text(regexp)
      Rails.logger.info("Creating new censor rule: /#{regexp}/")
      CensorRule.create!(:text => regexp,
                         :allow_global => true,
                         :replacement => _('REDACTED'),
                         :regexp => true,
                         :last_edit_editor => THEME_NAME,
                         :last_edit_comment => 'Added automatically')
    end

![Dirección editada encuadrada]({{ site.baseurl }}assets/img/redaction-address-quoted-redacted.png)

**Advertencia:** La edición de información desestructurada es una aproximación muy delicada, pues se apoya en que las autoridades siempre citen el texto completo.

En tal caso la autoridad ha revelado la fecha de nacimiento y el domicilio del usuario:

![Dirección fuera del bloque con formato]({{ site.baseurl }}assets/img/redaction-address-outside-fence.png)

Es realmente difícil añadir una <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">norma de censura</a> para eliminar este tipo de información. Una sugerencia puede ser eliminar todas las menciones de la fecha de nacimiento del usuario, pero debería tener en cuenta [todos los tipos de formato de fecha](http://en.wikipedia.org/wiki/Calendar_date#Date_format). Probablemente podría editar todas las apariciones del domicilio del usuario, pero si se trata de una solicitud relacionada con su región, es muy probable que esta se volviera incomprensible.

![Norma de censura para editar el domicilio del usuario]({{ site.baseurl }}assets/img/redaction-domicile-censor-rule.png)

La edición se ha aplicado, pero no hay forma de conocer el contexto en que se utiliza una palabra delicada.

![Norma de censura para editar el domicilio del usuario]({{ site.baseurl }}assets/img/redaction-domicile-censor-rule-applied.png)
