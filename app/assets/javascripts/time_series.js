function timeSeries(selector, url, metric) {

  // Add the title
  var wrapper_element = document.querySelectorAll(selector)[0];

  var title_element = document.createElement('h4');
  title_element.classList.add("chart-title");
  title_element.textContent = "Number of " + metric + " over time";

  wrapper_element.insertBefore(title_element, wrapper_element.firstChild);

  // Add the chart
  d3.json(url, function(data) {

    // FIXME: Don't hardcode this to request hides by week
    data = data["requests"]["hides_by_week"].map(function(d, i) {
      return {key: new Date(d[0]), values: d[1]};
    });

    var width = 600;
    var barWidth = 5;
    var height = 100;
    var margin = { top: 20, right: 30, bottom: 100, left: 50 };
    var viewPortWidth = margin.left + width + margin.right;
    var viewPortHeight = margin.top + height + margin.bottom;

    var maxYValue = d3.max(data, function(datum) { return datum.values; });

    var x = d3.time.scale()
      .domain(
        d3.extent(data, function(datum) { return datum.key; })
      )
      .range([0, width]);

    var y = d3.scale
      .linear()
      .domain([0, maxYValue])
      .rangeRound([height, 0]);

    var bisectDate = d3.bisector(function(d) { return d.key; }).left

    var yTickCount;
    if (maxYValue < 3) {
      yTickCount = Math.floor(maxYValue);
    } else {
      yTickCount = 3;
    }

    var yAxis = d3.svg.axis()
      .scale(y)
      .ticks(yTickCount)
      .tickFormat(d3.format("s"))
      .tickPadding(8)
      .orient("left");

    var xTickCount,
        xDomainMonths = d3.time.months(x.domain()[0], x.domain()[1]).length;
    if (xDomainMonths < 9) {
      xTickCount = 2;
    } else {
      xTickCount = (d3.time.months, 10);
    }

    var xAxisDateFormats = d3.time.format.multi([
        ["%_d %b", function(d) { return d.getDate() != 1; }],
        ["%b", function(d) { return d.getMonth(); }],
        ["%Y", function() { return true; }]
    ]);

    var xAxis = d3.svg.axis()
      .scale(x)
      .ticks(xTickCount)
      .tickFormat(xAxisDateFormats)
      .tickPadding(8);

    var focusCallout = d3.select(selector)
          .append("div")
          .attr("class", "chart-callout")
          .append("h5"),
        focusCalloutValue = focusCallout.append("span")
          .attr("class", "chart-callout-heading"),
        focusCalloutDate = focusCallout.append("span")
          .attr("class", "chart-callout-subheading");

    // add the canvas to the DOM
    var chart = d3.select(selector)
      .attr("class", "chart chart-with-callout")
      .append("svg:svg")
      .attr("width", "100%")
      .attr("height", "100%")
      .attr("viewBox", "0 0 " + viewPortWidth + " " + viewPortHeight )
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var areaValues = d3.svg.area()
      .x(function(d) { return x(d.key); })
      .y0(height)
      .y1(function(d) { return y(d.values); })
      .interpolate("monotone");

    var lineValues = d3.svg.line()
      .x(function(d) { return x(d.key); })
      .y(function(d) { return y(d.values); })
      .interpolate("monotone");

    chart.append("g")
      .attr("class", "x-axis")
      .attr("transform", "translate(0, " + (height + 8) + ")")
      .call(xAxis);

    chart.append("g")
      .attr("class", "y-axis")
      .attr("transform", "translate(-8, 0)")
      .call(yAxis);

    chart.append("line")
      .attr("class", "x-axis-baseline")
      .attr("x1", 0)
      .attr("y1", height)
      .attr("x2", width)
      .attr("y2", height);

    chart.append("svg:path")
      .attr("d", areaValues(data))
      .attr("class", "chart-area");

    // Clip the line a y(0) so 0 values are more prominent
    chart.append("clipPath")
      .attr("id", "clip-above")
      .append("rect")
      .attr("width", width)
      .attr("height", y(0) - 1);

    chart.append("clipPath")
      .attr("id", "clip-below")
      .append("rect")
      .attr("y", y(0))
      .attr("width", width)
      .attr("height", height);

    chart.selectAll(".chart-line")
      .data(["above", "below"])
      .enter()
      .append("path")
      .attr("class", function(d) { return "chart-line chart-clipping-" + d; })
      .attr("clip-path", function(d) { return "url(#clip-" + d + ")"; })
      .datum(data)
      .attr("d", lineValues);

    var focus = chart.append("g")
      .attr("class", "focus");

    focus.append("circle")
      .attr("r", 5);

    focus.append("text")
      .attr("x", 9)
      .attr("dy", -10);

    focusDefault();

    chart.append("rect")
      .attr("class", "chart-overlay")
      .attr("width", width)
      .attr("height", height)
      .on("mouseout", focusDefault)
      .on("mousemove", mousemove);

    function focusDefault() {
      var finalPoint = data[data.length - 1],
          focusDefaultPosition = {
            x: x(finalPoint.key),
            y: y(finalPoint.values)
          };

      focus.attr("transform", "translate(" + focusDefaultPosition.x + "," + focusDefaultPosition.y + ")");
      focus.select("text").text(finalPoint.values);

      setCalloutText(finalPoint);
    }

    function setCalloutText(point) {
      var weekEnd = d3.time.week.offset(point.key, 1),
          weekStartFormat = d3.time.format("%d %b"),
          weekEndFormat = d3.time.format("%d %b %Y"),
          dateSpan = weekStartFormat(point.key) + " – " + weekEndFormat(weekEnd);

      focusCalloutValue.text(point.values + " " + metric);
      focusCalloutDate.text(dateSpan);
    }

    function mousemove() {
      var x0 = x.invert(d3.mouse(this)[0]),
      i = bisectDate(data, x0, 1),
      d0 = data[i - 1],
      d1 = data[i],
      d = x0 - d0.date > d1.date - x0 ? d1 : d0,
      yValue = height - y(d.values);
      focus.attr("transform", "translate(" + x(d.key) + "," + y(d.values) + ")");
      focus.select("text").text(d.values);

      setCalloutText(d);
    }
  });

}
