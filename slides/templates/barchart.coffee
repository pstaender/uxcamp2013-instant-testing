$('#barchart').html('')

margin =
  top: 20
  right: 20
  bottom: 30
  left: 40

width = 960 - margin.left - margin.right
height = 500 - margin.top - margin.bottom
formatPercent = d3.format(".0%")
x = d3.scale.ordinal().rangeRoundBands([0, width], .1)
y = d3.scale.linear().range([height, 0])
xAxis = d3.svg.axis().scale(x).orient("bottom")
yAxis = d3.svg.axis().scale(y).orient("left").tickFormat(formatPercent)
svg = d3.select("#barchart").append("svg").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")


loadBarchart = ->
  d3.tsv "data.tsv", (error, data) ->
    data.forEach (d) ->
      d.frequency = +d.frequency

    # x.domain data.sort((a,b)-> b.frequency - a.frequency).map((d) -> d.letter )
    x.domain data.map((d) -> d.letter)
    
    y.domain [0, d3.max(data, (d) ->
      d.frequency #height
    )]
    svg.selectAll(".bar").data(data).enter().append("rect").attr("class", "bar").attr("x", (d) ->
      x d.letter
    ).attr("width", x.rangeBand()).attr("y", (d) ->
      y d.frequency
    ).attr "height", (d) ->
      height - y(d.frequency)

loadBarchart()
