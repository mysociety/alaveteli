(function($) {

  $(function(){

    // The size of the initial selection (largest, centreted rectangle)
    var w = jQuery('#profile_photo_cropbox').width();
    var h = jQuery('#profile_photo_cropbox').height();
    var t = 0;
    var l = 0;
    var initial;
    if (h < w) {
      initial = h;
      l = (w - initial) / 2;
    } else {
      initial = w;
      t = (h - initial) / 2;
    }

    var jcrop_api;
    var bounds, boundx, boundy;

    $('#profile_photo_cropbox').Jcrop({
      onChange: showPreview,
      onSelect: showPreview,
      aspectRatio: 1
    },function(){
      jcrop_api = this;
      bounds = jcrop_api.getBounds();
      boundx = bounds[0];
      boundy = bounds[1];
    });

    jcrop_api.setSelect([ l, t, initial, initial ]);

    function showPreview(coords)
    {
      if (parseInt(coords.w) > 0)
      {
        var rx = 100 / coords.w;
        var ry = 100 / coords.h;

        $('#profile_photo_preview').css({
          width: Math.round(rx * boundx) + 'px',
          height: Math.round(ry * boundy) + 'px',
          marginLeft: '-' + Math.round(rx * coords.x) + 'px',
          marginTop: '-' + Math.round(ry * coords.y) + 'px'
        });

        $('#x').val(coords.x);
        $('#y').val(coords.y);
        $('#w').val(coords.w);
        $('#h').val(coords.h);
      }
    };

  });

}(jQuery));

