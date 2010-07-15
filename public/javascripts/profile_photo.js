// Remember to invoke within jQuery(window).load(...)
// If you don't, Jcrop may not initialize properly
jQuery(window).load(function(){

    jQuery('#profile_photo_cropbox').Jcrop({
        onChange: showPreview,
        onSelect: showPreview,
        aspectRatio: 1
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
            width: Math.round(rx * 500) + 'px',
            height: Math.round(ry * 370) + 'px',
            marginLeft: '-' + Math.round(rx * coords.x) + 'px',
            marginTop: '-' + Math.round(ry * coords.y) + 'px'
        });
    }
}

