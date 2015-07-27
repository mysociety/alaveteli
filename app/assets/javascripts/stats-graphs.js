/* From http://stackoverflow.com/a/10284006/223092 */
function zip(arrays) {
  return arrays[0].map(function(_,i){
    return arrays.map(function(array){return array[i]})
  });
}

$(document).ready(function() {
  $.each(graphs_data, function(index, graph_data) {
    var graph_id = graph_data.id,
    dataset,
    plot,
    graph_data,
    graph_div = $('#' + graph_id),
    previousPoint = null;

    if (!graph_data.x_values) {
      /* Then there's no data for this graph */
      return true;
    }

    graph_div.css('width', '700px');
    graph_div.css('height', '600px');

    dataset = [
      {'color': 'orange',
      'bars': {
        'show': true,
        'barWidth': 0.5,
        'align': 'center'
      },
      'data': zip([graph_data.x_values,
        graph_data.y_values])
      }
    ]

    if (graph_data.errorbars) {
      dataset.push({
        'color': 'orange',
        'points': {
          // Don't show these, just draw error bars:
          'radius': 0,
          'errorbars': 'y',
          'yerr': {
            'asymmetric': true,
            'show': true,
            'upperCap': "-",
            'lowerCap': "-",
            'radius': 5
          }
        },
        'data': zip([graph_data.x_values,
          graph_data.y_values,
          graph_data.cis_below,
          graph_data.cis_above])
        });
      }

      options = {
        'grid': { 'hoverable': true, 'clickable': true },
        'xaxis': {
          'ticks': graph_data.x_ticks,
          'rotateTicks': 90
        },
        'yaxis': {
          'min': 0,
          'max': graph_data.y_max
        },
        'xaxes': [{
          'axisLabel': graph_data.x_axis,
          'axisLabelPadding': 20,
          'axisLabelColour': 'black'
        }],
        'yaxes': [{
          'axisLabel': graph_data.y_axis,
          'axisLabelPadding': 20,
          'axisLabelColour': 'black'
        }],
        'series': {
          'lines': {
            'show': false
          }
        },
      }

      plot = $.plot(graph_div,
        dataset,
        options);

        graph_div.bind("plotclick", function(event, pos, item) {
          var i, pb, url, name;
          if (item) {
            i = item.dataIndex;
            pb = graph_data.public_bodies[i];
            url = pb.url;
            name = pb.name;
            window.location.href = url;
          }
        });

        /* This code is adapted from:
        http://www.flotcharts.org/flot/examples/interacting/ */

        function showTooltip(x, y, contents) {
          $('<div id="flot-tooltip">' + contents + '</div>').css({
            'position': 'absolute',
            'display': 'none',
            'top': y + 10,
            'left': x + 10,
            'border': '1px solid #fdd',
            'padding': '2px',
            'background-color': '#fee',
            'opacity': 0.80
          }).appendTo("body").fadeIn(200);
        }

        graph_div.bind("plothover", function (event, pos, item) {
          var escapedName, x, y;
          if (item) {
            if (previousPoint != item.dataIndex) {
              previousPoint = item.dataIndex;
              $("#flot-tooltip").remove();
              escapedName = $('<div />').text(
                graph_data.tooltips[item.dataIndex]).html();
                showTooltip(item.pageX,
                  item.pageY,
                  escapedName);
                }
              } else {
                $("#flot-tooltip").remove();
                previousPoint = null;
              }
            });
          });
        });
