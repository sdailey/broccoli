
$(document).ready( -> 
  
  recentlyVotedPoints = []
  cachedVotedPoints = []
  
  viewElementId = ''
  
  renderedBool = false
  
  userVotes = (userAgreedBool, serviceName, pointId) ->
    
    parcel =
      'msg': 'post_userVote'
      'userAgreedBool': userAgreedBool
      'serviceName': serviceName
      'pointId': pointId
    
    sendParcel(parcel)
  
  backupViewElsToUnbind = []
  
  backupView = (viewData, backPointId) ->
    
    for el in backupViewElsToUnbind
      el.unbind()
    backupViewElsToUnbind = []
    
    $('#backupView').children().unbind()
    
    viewElementId = 'backupView'
    
    $("#backupView").css('display','block')
    $("#pointSummaryView").css('display','none')
    $("#historyView").css('display','none')
    
    $('#backupView').html("")
    
    UIbarHtmlString = ''
    
    if viewData.popupParcel.nullOrCachedServices?
      # console.log 'safdasdfsadfasdf'
      # console.debug viewData.popupParcel.nullOrCachedServices
      dataPretty = "text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(viewData.popupParcel.nullOrCachedServices, null, 2));
      data = "text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(viewData.popupParcel.nullOrCachedServices));
      UIbarHtmlString += '<a id="clickJSON" href="data:' + dataPretty + '" download="tosdr-term-opinions.json">Click here to export formatted data.</a><br><br>'
      UIbarHtmlString += '<a id="clickJSON" href="data:' + data + '" download="tosdr-term-opinions.json">Click here to export raw data.</a>'
    else
      UIbarHtmlString += "You haven't reviewed any terms."
      
      
    UIbarHtmlString += '<table class="pointListItem" style="text-align: left; width: 100%; margin-top:5px; margin-bottom:10px;" border="0" cellpadding="0" cellspacing="0"><tbody><tr>'
    UIbarHtmlString +=   '<td style="padding:10px; vertical-align: top; text-align: center; width: 100%;" class="backPointId" data-pointid="' + backPointId + '"><button class="btn" style="font-size: 1em;background-color: rgb(232, 249, 255);padding:3px;"> back </button></td>'
    UIbarHtmlString += '</tr></tbody></table>'
    
    $('#backupView').html(UIbarHtmlString)
    
    el_backPointId = $('.backPointId')
    backupViewElsToUnbind.push el_backPointId
    
    $('.backPointId').bind('click', (ev) ->
      $('#pointSummaryView').children().unbind()
      renderMainView(viewData, $(ev.currentTarget).data('pointid'))
    )
  
  historyViewElsToUnbind = []
  
  renderHistoryView = (viewData, backPointId) ->
    
    for el in historyViewElsToUnbind
      el.unbind()
    historyViewElsToUnbind = []
    
    viewElementId = 'summaryView'
    
    
    $("#backupView").css('display','none')
    $("#pointSummaryView").css('display','none')
    $("#historyView").css('display','block')
    
    $('#historyView').children().unbind()
    
    $('#historyView').html("<span id='votedOnKeys'> </span>")
      
    pointItemsHtmlString = '' # title # you said yes
    
    # pointItemsHtmlString += '<div style="position:relative;width:100%;" class="pointListItem" data-pointid="' + backPointId + '">'
    # pointItemsHtmlString += '<span style="float:left;" class="historyPointId" data-pointid="' + backPointId + '">back</span> <span style="">- credits -</span><span style="float:right;"> settings </span></div>'
    
    
    for pointId, cachedVotedPointsArray of viewData.cachedVotedPoints
      pointItem = _.last cachedVotedPointsArray
      if pointItem.voteAgree
        agreedClass = 'agreed'
        agreeLable = 'btn-success'
        htmlString = 'agreed'
      else
        agreedClass = 'disagreed'
        agreeLable = 'btn-danger'
        htmlString = 'disagreed'
      
      # pointItemsHtmlString += '<table><tbody><tr>' 
      pointItemsHtmlString += '<div class="historyPointId pointListItem ' + agreedClass + '" data-pointid="' + pointItem.canonical.id + '">'
      pointItemsHtmlString += '<button type="button" class="btn ' + agreeLable + ' userDecision">' + htmlString + '</button>'
      pointItemsHtmlString += '<div class="pointTitle">'+ pointItem.canonical.title  #style="inline-block"
      pointItemsHtmlString += '</div>'
      
      pointItemsHtmlString += '</div>'
    
    for pointId, pointItem of viewData.toVotePoints
      
      # pointItemsHtmlString += '<table><tbody><tr>' 
      pointItemsHtmlString += '<div class="historyPointId pointListItem undecidedItem" data-pointid="' + pointItem.id + '">'
      pointItemsHtmlString += '<button type="button" class="btn userDecision"> undecided </button>'
      pointItemsHtmlString += '<div class="pointTitle">'+ pointItem.title  #style="inline-block"
      pointItemsHtmlString += '</div>'
      
      pointItemsHtmlString += '</div>'
      
    UIbarHtmlString = ''
    UIbarHtmlString += '<table class="pointListItem" style="text-align: left; width: 100%; margin-top:5px; margin-bottom:10px;" border="0" cellpadding="0" cellspacing="0"><tbody><tr>'
    UIbarHtmlString +=   '<td style="padding:10px; vertical-align: top; text-align: center; width: 33%;" class="historyPointId" data-pointid="' + backPointId + '"><button class="btn" style="font-size: 1em;background-color: rgb(232, 249, 255);padding:3px;"> back </button></td>'
    UIbarHtmlString +=   '<td style="padding:10px; vertical-align: top; text-align: center; width: 34%;"><button class="btn" style="font-size: 1em;background-color: rgb(232, 249, 255);padding:3px;" id="exportData"> export <span style="font-size:0.8em;">&darr;</span> </button></td>'
    UIbarHtmlString +=   '<td style="padding:10px; vertical-align: top; text-align: center; width: 33%;" id="clearService"><button class="btn" style="font-size: 1em;background-color: rgb(232, 249, 255);padding:3px;"> clear </button></td>'
    UIbarHtmlString += '</tr></tbody></table>'
    
    renderHtmlString = ''
    if Object.keys(viewData.cachedVotedPoints).length + Object.keys(viewData.toVotePoints).length > 7
      renderHtmlString = UIbarHtmlString + pointItemsHtmlString
    else
      renderHtmlString = pointItemsHtmlString + UIbarHtmlString
    
    $('#votedOnKeys').html(renderHtmlString)
    
    el_historyPointId = $('.historyPointId')
    
    historyViewElsToUnbind.push el_historyPointId
    
    $('.historyPointId').bind('click', (ev) ->
      $('#pointSummaryView').children().unbind()
      renderMainView(viewData, $(ev.currentTarget).data('pointid'))
    )
    
    el_clearService = $('#clearService')
    historyViewElsToUnbind.push el_clearService
    $('#clearService').bind('click', (ev) ->
      sendObj =
        msg: 'post_clearService'
        serviceName: viewData.serviceInfo.serviceName
      sendParcel(sendObj)
    )
    
    el_exportData = $('#exportData')
    historyViewElsToUnbind.push el_exportData
    $('#exportData').bind('click', (ev) ->
      backupView(viewData, backPointId)
    )
      
    $('body').removeAttr('style');
    $('html').removeAttr('style');
    renderExtensionHeight('historyView', 1)
    
    $($('a')[0]).blur()
  
  mainViewElsToUnbind = []
  
  cleanupMainView = ->
    $('#credits-attributions-box').hide()
    $('#share-box-textarea').hide()
   
  renderMainView = (viewData, specificPointId = null) ->
    
    $('#pointSummaryView').children().unbind()
    
    for el in mainViewElsToUnbind
      el.unbind()
    mainViewElsToUnbind = []
    
    
    
    viewElementId = 'pointSummaryView'
    
    serviceCapped = capitalizeFirstLetter(viewData.serviceInfo.serviceName)
    
    $("#pointSummaryView").css('display','block')
    $("#historyView").css('display','none')
    $("#backupView").css('display','none')
    
    # console.log 'console.debug viewData'
    # console.debug viewData
    # console.log 'specificPointId'
    # console.debug specificPointId
    
    toVotePointIds = Object.keys viewData.toVotePoints
    
    if specificPointId? and viewData.cachedVotedPoints[specificPointId]?
      
      # console.log 'console.debug viewData.popupParcel.servicesFull'
      # console.debug viewData.popupParcel.servicesFull
      # console.debug viewData.popupParcel
      # console.debug specificPointId
      
      specificPoint = viewData.popupParcel.servicesFull[viewData.popupParcel.serviceName].service.pointsData[specificPointId]
      
      renderPoint = thisPoint(specificPoint, _.last(viewData.cachedVotedPoints[specificPointId]))
      
    else if specificPointId? and viewData.toVotePoints[specificPointId]?
      
      renderPoint = thisPoint(viewData.toVotePoints[specificPointId])
      
    else
      
      
      
      if toVotePointIds.length < 2
        
        randIndex = 0
        renderPoint = thisPoint(viewData.toVotePoints[toVotePointIds[randIndex]])
      else  
        preferAbleTldrLengthPointHash = {}
        
        if renderedBool is false 
          # if it's the first time the popup opens, find a tldr summary that's not too long
          for pointId, point of viewData.toVotePoints
            
            if point.tosdr.tldr.length < 380 and point.tosdr.tldr.length > 10
              preferAbleTldrLengthPointHash[pointId] = point
          
          if Object.keys(preferAbleTldrLengthPointHash).length < 2
            randIndex = getRandom(0, toVotePointIds.length - 1)
            renderPoint = thisPoint(viewData.toVotePoints[toVotePointIds[randIndex]])
          else
            prefLengthPointIds = Object.keys(preferAbleTldrLengthPointHash)
            randIndex = getRandom(0, prefLengthPointIds.length - 1)
            renderPoint = thisPoint(preferAbleTldrLengthPointHash[prefLengthPointIds[randIndex]])
              
        else
          
          randIndex = getRandom(0, toVotePointIds.length - 1)
          renderPoint = thisPoint(viewData.toVotePoints[toVotePointIds[randIndex]])
        
        
        
    
    allPointIds = _.union Object.keys(viewData.cachedVotedPoints), toVotePointIds
    
    remainingPoints = _.without allPointIds, renderPoint.id
    
    renderedBool = true
    
    
    shareBlobString = ''
    
      
    # console.log 'console.debug renderPoint'
    # console.debug renderPoint
    
    shareBlobString += renderPoint.title + "&#13;&#10;&#13;&#10;"
    
    $("#landingTitle").html(renderPoint.title)
    
    permaPointUrl = 'https://tosdr.org/?servicePoint=' + viewData.serviceInfo.serviceName + '__' + renderPoint.id
    
    shareBlobString += "Permalink: " + permaPointUrl + "&#13;&#10;&#13;&#10;"
    
    if renderPoint.tldr? and renderPoint.tldr != renderPoint.title
      shareBlobString += "Summary:" + renderPoint.tldr + "&#13;&#10;&#13;&#10;"
      $("#landingSummary #textDropLanding").html(renderPoint.tldr)
    
    if viewData.serviceInfo.twitter? 
      shareBlobString += serviceCapped + " on Twitter: " + viewData.serviceInfo.twitter + "&#13;&#10;&#13;&#10;"
    
    pointHtmlString = ''
    cellCount = 0
    if renderPoint.discussion?
      cellCount++
      pointHtmlString += '<td class="linkTableCell variableWidthCell">'
      pointHtmlString +=   "<a target='_blank' href='" + renderPoint.discussion + "' title='" + renderPoint.discussion + "'> discuss </a>"
      pointHtmlString += '</td>'
      shareBlobString += "Discussion on Google Groups: " + renderPoint.discussion + "&#13;&#10;&#13;&#10;"
    if renderPoint.source?
      if _.isArray(renderPoint.source)
        for link, index in renderPoint.source
          if isProbablyAUrl(link)
            cellCount++
            pointHtmlString += '<td class="linkTableCell variableWidthCell">'
            pointHtmlString += "<a target='_blank' href='" + link + "' title='" + link + "' > link " + (index + 1) + " </a>"
            pointHtmlString += '</td>'
            shareBlobString += "Link " + (index + 1) + ": " + link + "&#13;&#10;"
      else if _.isObject(renderPoint.source)
        for linkName, href of renderPoint.source
          if isProbablyAUrl(href)
            cellCount++
            pointHtmlString += '<td class="linkTableCell variableWidthCell">'
            pointHtmlString += "<a target='_blank' href='" + href + "' title='" + href + "'> " + linkName + " </a>"
            pointHtmlString += '</td>'
            
            shareBlobString += linkName + ": " + href + "&#13;&#10;"
    
    
    
    cellCount++
    shareHtmlString = '<td class="linkTableCell variableWidthCell">'
    shareHtmlString += '<div id="share-button">'
    shareHtmlString +=  '<button class="btn" id="open-share-box-textarea" style="font-size: 1em;background-color: rgb(232, 249, 255);padding:3px;margin-top:2px;" > <img src="/shareSpritesPNG.png" alt="copy" /> </button>'
    
    # shareHtmlString += ' <a href="http://cnn.com">  </a>'
    shareHtmlString += '</div>'
    shareHtmlString += '</td>'
    
    cellCount++
    pointHtmlString += shareHtmlString
    
    cellWidth = parseInt(100/cellCount)
    
    if pointHtmlString != ''
      pointHtmlString = '<table class="slotMain" border="0" cellpadding="0" cellspacing="0"><tbody><tr>' + pointHtmlString
      pointHtmlString += '</tr></tbody></table>'
    
    
    $('#pointDropBox').html(pointHtmlString)
    
    $('.variableWidthCell').css('width',cellWidth+'%')
    
    serviceHtmlString = '<span style="font-size: 1.2em;line-height: 2.3em;"> <b>' + serviceCapped + "</b></span><br>"
    
    if viewData.serviceInfo.twitter?
      serviceHtmlString += "<a target='_blank' href='https://twitter.com/" + viewData.serviceInfo.twitter + "' > " + viewData.serviceInfo.twitter + " </a> <br>"
       
    
    if viewData.serviceInfo.links?
      shareBlobString += "&#13;&#10;"
      shareBlobString += serviceCapped + ": &#13;&#10;"
      
      for linkType, linkObj of viewData.serviceInfo.links
        if isProbablyAUrl(linkObj.url)
          serviceHtmlString += "<a target='_blank' href='" + linkObj.url + "' > " + linkObj.name + " </a> <br>"
        
        shareBlobString += linkObj.name + ": " + linkObj.url + " &#13;&#10;"
      
    shareBlobString += "Service summary for " + viewData.serviceInfo.serviceName + ": " + "https://tosdr.org/index.html?service=" + viewData.serviceInfo.serviceName + " &#13;&#10;"
        
    serviceHtmlString += "<br><a class='btn' style='font-size: 1em;background-color: rgb(232, 249, 255); font-color:black;' target='_blank' href='https://tosdr.org/index.html?service=" + viewData.serviceInfo.serviceName + "' > service overview </a> <br>"
    
    $('#serviceDropBox').html(serviceHtmlString)
    
    
    creditsHtmlString = ''
    
    creditsHtmlString += "<br><a target='_blank' href='https://tosdr.org/get-involved.html' ><strong>Get involved!</strong><br>Submit a point, update information, more!</a> <br><br>"
    
    creditsHtmlString += "<span id='open-credits-attributions-box' style='color:blue;2'>credits</span> <br>"
    
    $("#creditsDropBox").html(creditsHtmlString)
    
    shareBlobString = '<button class="btn" id="close-share-box-textarea" style="float:right;margin-bottom: 10px;"> close </button><textarea>' + shareBlobString + '</textarea>'
    
    shareBlobString = "<span style='position: relative;font-size: 1.3em;top: 4px;'>Here's a start! Shareable text:</span> " + shareBlobString
    
    $("#share-box-textarea").html(shareBlobString)
    
    el_openCreditsAttributionsBox = $('#open-credits-attributions-box')
    el_creditsAttributionsBox = $('#credits-attributions-box')
    el_openCreditsAttributionsBox.bind('click', (ev) ->
      # $('#credits-attributions-box').css('display','block')
      if el_creditsAttributionsBox.css('display') is 'none'
        el_creditsAttributionsBox.show(700)
      else
        el_creditsAttributionsBox.hide(700)
    )
    mainViewElsToUnbind.push el_openCreditsAttributionsBox
    
    el_openShareBoxTextarea = $('#open-share-box-textarea')
    
    el_openShareBoxTextarea.bind('click', (ev) ->
      # $('#share-box-textarea').show(700)
      
      if $('#share-box-textarea').css('display') is 'none'
        $('#share-box-textarea').show(700)
      else
        $('#share-box-textarea').hide(700)
    )
    el_closeShareBoxTextarea = $('#close-share-box-textarea')
    el_closeShareBoxTextarea.bind('click', (ev) ->
      $('#share-box-textarea').hide(700)
    )
    mainViewElsToUnbind.push el_closeShareBoxTextarea
    
    creditsBoxHtmlString = ''
    
    creditsBoxHtmlString += '<button class="btn" id="close-credits-attributions-box" style="float:right; margin-bottom: 10px;"> close </button>'
    
    if renderPoint.meta?
      
      if renderPoint.meta['author']?
        creditsBoxHtmlString += "<strong>Summary author</strong>: " + htmlEntities(renderPoint.meta['author']) + "<br>"
      
      if renderPoint.meta['contributors']? and renderPoint.meta['contributors'].length > 0
        
        if renderPoint.meta['contributors'].length == 1
          creditsBoxHtmlString += "<strong>Contributor</strong>: " + htmlEntities(renderPoint.meta['contributors'][0]) + "<br>"
          
        else
          creditsBoxHtmlString += "<strong>Contributors</strong>: <br>"
          for contributor in renderPoint.meta['contributors']
            creditsBoxHtmlString +=  htmlEntities(contributor) + "<br>"
            
      if renderPoint.meta['license-for-this-file']?
        creditsBoxHtmlString += "<strong>License for summary file</strong>: " + htmlEntities(renderPoint.meta['license-for-this-file']) + "<br>"
    
    creditsBoxHtmlString += '<br><ul>'
    
    creditsBoxHtmlString += "<li><a target='_blank' href='https://tosdr.org/about.html' > about TOS;DR - <strong>terms of service; didn't read</strong></a></li> <br>" 
    creditsBoxHtmlString += "<li><a target='_blank' href='https://github.com/tosdr/tosdr.org/graphs/contributors' >code contributors to TOS;DR web service</a></li> <br>" 
    
    creditsBoxHtmlString += "<li><a target='_blank' href='https://eff.org' >EFF</a> and <a target='_blank' href='https://www.internetsociety.org/' >Internet Society</a> collaborate with TOS;DR on <a target='_blank' href='https://tosback.org/' >TOSBack</a>, a service which aims to provide greater reliability and coverage in term summaries.</li> <br>" 
    
    creditsBoxHtmlString += "<li><a target='_blank' href='https://www.flickr.com/photos/darwinbell/314088675/in/faves-56737858@N04/' > broccoli's logo image </a></li> <br>"
    
    creditsBoxHtmlString += "<li>broccoli <a target='_blank' href='https://github.com/sdailey/broccoli' >github</a>, <a target='_blank' href='https://twitter.com/spencenow' >author</a></li><br>"
    
    creditsBoxHtmlString += "</ul>"
    
    $('#credits-attributions-box').html(creditsBoxHtmlString)
    
    el_closeCreditsAttributionsBox = $('#close-credits-attributions-box')
    el_closeCreditsAttributionsBox.bind('click', (ev) ->
      $('#credits-attributions-box').hide(600)
    )
    mainViewElsToUnbind.push el_closeCreditsAttributionsBox
    
    voteHtmlString = '<button id="yes-' + renderPoint.id + '" class="btn" > yes </button>'
    $("#yesDrop").html(voteHtmlString)
    voteHtmlString = '<button id="no-' + renderPoint.id + '" class="btn" > no </button>'
    $("#noDrop").html(voteHtmlString)
    
    $(".voteYes button").removeAttr('style')
    $(".voteNo button").removeAttr('style')
    
    el_noDrop = $('#noDrop')
    mainViewElsToUnbind.push el_noDrop
    el_yesDrop = $('#yesDrop')
    mainViewElsToUnbind.push el_yesDrop
    if renderPoint.voteAgree?
      if renderPoint.voteAgree
        $(".voteYes button").css('background-color','rgb(110, 226, 110)')
        
        el_noDrop.bind('click', (ev) ->
          userVotes(false, viewData.serviceInfo.serviceName, renderPoint.id)
          cleanupMainView()
        )
        
      else
        $(".voteNo button").css('background-color','rgba(255, 19, 19, 0.71)')
        
        el_yesDrop.bind('click', (ev) ->
          userVotes(true, viewData.serviceInfo.serviceName, renderPoint.id)
          cleanupMainView()
        )
        
    else
      
      $('#yesDrop').bind('click', (ev) ->
        userVotes(true, viewData.serviceInfo.serviceName, renderPoint.id)
        cleanupMainView()
      )
      
      $('#noDrop').bind('click', (ev) ->
        userVotes(false, viewData.serviceInfo.serviceName, renderPoint.id)
      )
    
    
    if remainingPoints.length > 0
      el_goToNext = $('#goToNext')
      mainViewElsToUnbind.push el_goToNext
      $('#goToNext').bind('click', (ev) ->
        if remainingPoints.length < 2
          randIndex = 0
        else  
          randIndex = getRandom(0, remainingPoints.length - 1)
        
        $('#pointSummaryView').children().unbind()
        
        
        
        cleanupMainView()
        
        # console.log 'console.log randIndex'
        # console.log randIndex
        # console.log 'console.debug toVotePointIds'
        # console.debug toVotePointIds
        
        renderMainView(viewData, remainingPoints[randIndex])
        
      )
      
    else
      $('#goToNext').remove()
    
    el_goToHistoryView = $('.goToHistoryView')
    mainViewElsToUnbind.push el_goToHistoryView
    el_goToHistoryView.bind('click', (ev) ->
      $('#historyView').children().unbind()
      
      $('credits-attributions-box').remove()
      $('share-box-textarea').remove()
      
      renderHistoryView(viewData, renderPoint.id)
    )
    
    $('body').removeAttr('style');
    
    
    pointStatsHtml = ''
    pointStatsHtml += allPointIds.length + ' points total. <br>'
    pointStatsHtml += Object.keys(viewData.toVotePoints).length + ' left to review.'
    
    
    $("#pointStats").html(pointStatsHtml)
    
    setTimeout( -> # to reign in a chrome rendering issue
        renderExtensionHeight('pointSummaryView', 1)
        $($('a')[0]).blur()
        $($('button')[0]).blur()
      , 300
    )
    
    $($('a')[0]).blur()
    $($('button')).blur()
    return true
    
  receiveParcel  = (parcel) ->
    
    if !parcel.msg?
      
      return false
    
    switch parcel.msg
      
      when 'popupParcel_ready'
        # console.log "when 'popupParcel_ready'"
        # console.debug parcel
        
        chrome.tabs.getSelected(null,(tab) ->
          if tab.url is parcel.forUrl
            
            viewData = prepViewData(parcel.popupParcel)
            
            # console.log ' console.debug viewData'
            # console.debug viewData
            
            if Object.keys(viewData.toVotePoints).length is 0 and Object.keys(viewData.cachedVotedPoints).length > 0
                # and viewData.lastVotedPoint and viewData.lastVotedPoint.pointId? and viewData.lastVotedPoint.pointId != ''
              
              if Object.keys(viewData.cachedVotedPoints) < 2
                randIndex = 0
              else  
              
                randIndex = getRandom(0, Object.keys(viewData.cachedVotedPoints).length - 1)
                
              votedPointIds = Object.keys(viewData.cachedVotedPoints)
              
              renderMainView(viewData, votedPointIds[randIndex])
              
            else
              
              renderMainView(viewData, null)
              
              
            $("#landingStatusBox").html('Summaries available! :)')
        )
        
      when 'noServiceMatch'
      
        # console.log "when 'noServiceMatch'"
        $('body').removeAttr('style');
        $("body").html("<div style='width:380px;'>No summaries available for service. <a target='_blank' href='https://tosdr.org/get-involved.html' >Get involved to help change that!</a></div>")
        
        # console.debug parcel
      
      when 'popupParcel_pending'
        console.log "when 'popupparcel_pending'"
        
        # console.debug parcel
        $("#landingStatusBox").html('Trying to fetch service details...')
        # todo - waiting ...
  
   # data prep
  prepViewData = (popupParcel) ->
    
    serviceName = popupParcel.serviceName
    
    if popupParcel.nullOrCachedServices? and popupParcel.nullOrCachedServices[serviceName]? and popupParcel.nullOrCachedServices[serviceName].decisionPoints?
      cachedVotedPoints = popupParcel.nullOrCachedServices[serviceName].decisionPoints
    
    toVotePoints = popupParcel.pointsToVoteOn
    
    # cycledPoints = []
    
    if Object.keys(cachedVotedPoints).length > 0
      lastVotedPoint = 
        timestamp: 0
        pointId:''
      
      for pointId, decisionPointArray of cachedVotedPoints
        
        if _.last(decisionPointArray).timestamp > lastVotedPoint.timestamp
          lastVotedPoint.pointId = pointId
          lastVotedPoint.timestamp = _.last(decisionPointArray).timestamp
        
      
    else
      lastVotedPoint = null
    
    
    
    if popupParcel.nullOrCachedServices? and popupParcel.nullOrCachedServices[popupParcel.serviceName]?
      serviceCache = popupParcel.nullOrCachedServices[popupParcel.serviceName]
    else
      serviceCache = null
    viewData = {
      'serviceInfo':{'serviceName':popupParcel.serviceName}  
      'cachedVotedPoints': cachedVotedPoints
      'toVotePoints': toVotePoints
      'serviceCache': serviceCache
      'popupParcel':popupParcel
      
      'lastVotedPoint':lastVotedPoint
      
      
      # 'cycledPoints': cycledPoints
      # 'recentlyVotedPoints': recentlyVotedPoints
    }
    
    if popupParcel.servicesFull[popupParcel.serviceName].service.twitter?
      viewData.serviceInfo.twitter = popupParcel.servicesFull[popupParcel.serviceName].service.twitter
    
    if popupParcel.servicesFull[popupParcel.serviceName].service.links?
      viewData.serviceInfo.links = popupParcel.servicesFull[popupParcel.serviceName].service.links
        
    return viewData
    
    # data prep
  addTargetAttribute = (rawTldr) ->
    
    if rawTldr.indexOf('target=') == -1 and rawTldr.indexOf('<a ') != -1
      
      fragsA = rawTldr.split('<a ')
      
      rebuiltTldr = ''
      
      for frag in fragsA
        if frag.length > 0
          rebuiltTldr += frag + "<a target='_blank' "
        
      return rebuiltTldr
    else
      return rawTldr
      
      
    # data prep
  thisPoint = (point, optionalDecisionPointCompanion = null) ->
    # console.log 'console.debug point console.debug optionalDecisionPointCompanion'
    # console.debug point
    # console.debug optionalDecisionPointCompanion
    
    
    tldr = addTargetAttribute(point.tosdr.tldr)
    
    viewPoint = {}
    if optionalDecisionPointCompanion?
      
      viewPoint.voteAgree = optionalDecisionPointCompanion.voteAgree
      viewPoint.shared = optionalDecisionPointCompanion.shared
    
    viewPoint.id = point.id
    viewPoint.tldr = tldr
    viewPoint.title = point.title
    
    if point.discussion?
      viewPoint.discussion = point.discussion
    if point.meta? and Object.keys(point.meta).length > 0
      viewPoint.meta = point.meta
    if point.source?
      
      if _.isObject point.source
        viewPoint.source = point.source
      else
        viewPoint.source = {}
        viewPoint.source['source'] = point.source
      
    return viewPoint     
  
    # listen for receipts
  port = chrome.extension.connect({name: "fromPopupToBackground"})
  
  sendParcel = (parcel) ->
    chrome.tabs.getSelected(null,(tab) ->
      
      parcel.forUrl = tab.url
      
      if !parcel.msg?
        return false
      
      switch parcel.msg
        when 'post_userVote'
          port.postMessage(parcel)
          
        when 'request_popupParcel'
          port.postMessage(parcel)
        
        when 'post_clearService'
          cachedVotedPoints = {}
          toVotePoints = {}
          popupParcel = {}
          port.postMessage(parcel)
          
    )
    
    # listen for other messages
  chrome.extension.onConnect.addListener((port) ->  
    if port.name is 'fromBackgroundToPopup'
      
      port.onMessage.addListener((pkg) ->
        receiveParcel(pkg)
      )
  )
  
  sendParcel({'msg':'request_popupParcel'})
  
  # port.postMessage({'msg':'request_popupParcel'})
  
  getRandom = (min, max) ->
    return min + Math.floor(Math.random() * (max - min + 1))
  
  renderExtensionHeight = (elementId, extraPx) ->
    if viewElementId is elementId
      extraPx = 2
      extHeight_ = $('#' + elementId).outerHeight() + extraPx
      
      # if extHeight_ > 590
      #   extHeight_ = 591
        
      # $('html').css('height',extHeight+'px')
      $('body').css('height', extHeight_ + 'px')
      `heightString = extHeight_.toString() +'px'`
      $('html').css('min-height', heightString)
      extHeight_--
      $('body').css('min-height', heightString)
      
  capitalizeFirstLetter = (string) ->
    return string.charAt(0).toUpperCase() + string.slice(1)

  # // http://css-tricks.com/snippets/javascript/htmlentities-for-javascript/
  htmlEntities = (str) ->
      return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  
  isProbablyAUrl = (s) ->
    
    if s.indexOf('http') != -1
      return true
    if s.indexOf('.com') != -1
      return true
    if s.indexOf('.net') != -1
      return true
    if s.indexOf('.org') != -1
      return true
    if s.indexOf('.us') != -1
      return true
    if s.indexOf('.de') != -1
      return true
    if s.indexOf('.fr') != -1
      return true
    if s.indexOf('.uk') != -1
      return true
    if s.indexOf('.cn') != -1
      return true
    if s.indexOf('www.') != -1
      return true
      
    if s.indexOf(' ') != -1
      return false
    
    if s.indexOf('/') != -1 and s.indexOf('.') != -1
      return true
    
    return false
)