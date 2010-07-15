// Remember to invoke within jQuery(window).load(...)
// If you don't, Jcrop may not initialize properly
jQuery(window).load(function(){
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

    jQuery('#profile_photo_cropbox').Jcrop({
        onChange: showPreview,
        onSelect: showPreview,
        aspectRatio: 1,
        setSelect: [ l, t, initial, initial ]
    });

});

// Our simple event handler, called from onChange and onSelect
// event handlers, as per the Jcrop invocation above
function showPreview(coords)
{
    if (parseInt(coords.w) > 0)
    {
        var rx = 100 / coords.w;
        var ry = 100 / coords.h;

        jQuery('#profile_photo_preview').css({
            width: Math.round(rx * jQuery('#profile_photo_cropbox').width()) + 'px',
            height: Math.round(ry * jQuery('#profile_photo_cropbox').height()) + 'px',
            marginLeft: '-' + Math.round(rx * coords.x) + 'px',
            marginTop: '-' + Math.round(ry * coords.y) + 'px'
        });

        $('#x').val(coords.x);
        $('#y').val(coords.y);
        $('#w').val(coords.w);
        $('#h').val(coords.h);
    }
}

