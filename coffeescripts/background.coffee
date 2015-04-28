

tabUrl = ''

serviceMatchObj = {
  # forUrl: 
  # serviceMatch: <bool>
}

updatesCountTest = 0

popupOpen = false

popupParcel = {
  # servicesCache
  # pointsToVoteOn
  # nullOrCachedServices
  # servicesFull
  # serviceName
  # forUrl
}
 
sendParcel = (parcel) ->
  outPort = chrome.extension.connect({name: "fromBackgroundToPopup"})
  
  if !parcel.msg? or !parcel.forUrl?
    return false
  
  switch parcel.msg
    when 'popupParcel_ready'
      # console.log "when 'popupParcel_ready'"
      # console.debug parcel 
      
      refreshBadge(parcel.popupParcel)
      
      outPort.postMessage(parcel)
      
    when 'noServiceMatch'
      outPort.postMessage(parcel)

  
updateMainViewData = (pointsToVoteOn, nullOrCachedServices, servicesFull, serviceName, forUrl) -> 
  
  popupParcel = 
    'pointsToVoteOn': pointsToVoteOn
    'nullOrCachedServices': nullOrCachedServices
    'servicesFull': servicesFull
    'serviceName': serviceName
  
  
  if popupOpen
    sendObj = 
      'popupParcel': popupParcel 
      'forUrl': forUrl
      'msg':'popupParcel_ready'
    
    sendParcel(sendObj)
    
  else
    
    refreshBadge(popupParcel)
    
messageMainView_noServiceMatch = (forUrl) ->
  sendObj = 
    'forUrl': forUrl
    'msg':'noServiceMatch'
    
  sendParcel(sendObj)

  
cacheService = (servicesCache, servicesFull, serviceName, currentTime, callback) ->
  if  !servicesCache[serviceName]?
    servicesCache[serviceName] = {}
    servicesCache[serviceName].canonicalTimestamp = currentTime
    servicesCache[serviceName].canonical = {}
    if servicesFull[serviceName].service.links?
      servicesCache[serviceName].canonical.links = servicesFull[serviceName].service.links
    if servicesFull[serviceName].service.twitter?
      servicesCache[serviceName].canonical.twitter = servicesFull[serviceName].service.twitter
    
    servicesCache[serviceName].decisionPoints = {}
    servicesCache[serviceName].sharedTotalResults = []
    
  else if ((currentTime - servicesCache[serviceName].canonicalTimestamp) < 86400000) # just refresh the canonical attributes
    servicesCache[serviceName].canonicalTimestamp = currentTime
    servicesCache[serviceName].canonical = {}
    if servicesFull[serviceName].service.links?
      servicesCache[serviceName].canonical.links = servicesFull[serviceName].service.links
    if servicesFull[serviceName].service.twitter?
      servicesCache[serviceName].canonical.twitter = servicesFull[serviceName].service.twitter
  
  chrome.storage.local.set({'servicesCache': servicesCache}, ->
    callback(servicesCache)
  )
    
cacheDecisionPoint = (servicesCache, servicesFull, serviceName, userAgreedBool, pointId, currentTime, callback) ->
  
  if servicesCache[serviceName]? and servicesFull[serviceName]? and servicesFull[serviceName].service.pointsData[pointId]?
    
    if !servicesCache[serviceName].decisionPoints[pointId]?
      
      servicesCache[serviceName].decisionPoints[pointId] = []
    
    rawPointData = servicesFull[serviceName].service.pointsData[pointId]
    
    canonical = 
      id: pointId
      title: rawPointData.title
    
    if rawPointData.tosdr? and rawPointData.tosdr.tldr?
      canonical['tldr'] = rawPointData.tosdr.tldr
    
    if rawPointData.meta?
      canonical['meta'] = rawPointData.meta
      
    if rawPointData.source?
      canonical.source = rawPointData.source
    
    if rawPointData.discussion?
      canonical.discussion = rawPointData.discussion
    
    setObj =
      'canonical': canonical
      'timestamp': currentTime
      'voteAgree': userAgreedBool
      'deleted': false
      'shared': []
    
    servicesCache[serviceName].decisionPoints[pointId].push setObj
    
    chrome.storage.local.set({'servicesCache': servicesCache}, ->
      
      callback(servicesCache, serviceName, pointId)
    )
  
cacheUserVote = (userAgreedBool, serviceName, pointId) ->
  currentTime = Date.now()
  
  
  chrome.storage.local.get('servicesFull', (response) ->
    
    if !response.servicesFull? or Object.keys(response.servicesFull).length is 0
      return false
    
    servicesFull = response.servicesFull
    
    # console.log 'servicesFull[serviceName]?'
    # console.log servicesFull[serviceName]?
    # console.log 'servicesFull[serviceName].service.pointsData[pointId]?'
    # console.log servicesFull[serviceName].service.pointsData[pointId]?
    
    if servicesFull[serviceName]? and servicesFull[serviceName].service.pointsData[pointId]?
      
      chrome.storage.local.get('servicesCache', (_r) ->
        
        if !_r.servicesCache? or Object.keys(_r.servicesCache).length is 0 or !_r.servicesCache[serviceName]? or 
            ((currentTime - _r.servicesCache[serviceName].canonicalTimestamp) < 86400000)
          
          if !_r.servicesCache?
            servicesCache = {}
          else
            servicesCache = _r.servicesCache
          cacheService( servicesCache , servicesFull, serviceName, currentTime, (_servicesCache) ->
            
            cacheDecisionPoint(_servicesCache, servicesFull, serviceName, userAgreedBool, pointId, currentTime, (__servicesCache, _serviceName, _pointId) ->
              
              getPointsToVoteOn(servicesFull, serviceName, (pointsToVoteOn, nullOrCachedServices) ->
                
                setObj = {}
                
                setObj.msg = 'popupParcel_ready'
                setObj.forUrl = tabUrl
                setObj.popupParcel =
                  'serviceName': _serviceName
                  'pointId': _pointId
                  'forUrl': tabUrl
                  'servicesFull': servicesFull
                  'pointsToVoteOn':pointsToVoteOn
                  'nullOrCachedServices': nullOrCachedServices
                
                popupParcel = setObj.popupParcel
                
                sendParcel(setObj)
                
              )
            )
          )
          
          
        else
        
          cacheDecisionPoint(_r.servicesCache, servicesFull, serviceName, userAgreedBool, pointId, currentTime, (__servicesCache, _serviceName, _pointId) ->
            
            getPointsToVoteOn(servicesFull, serviceName, (pointsToVoteOn, nullOrCachedServices) ->
              
              setObj = {}
              
              setObj.msg = 'popupParcel_ready'
              setObj.forUrl = tabUrl
              setObj.popupParcel =
                'serviceName': _serviceName
                'pointId': _pointId
                'forUrl': tabUrl
                'servicesFull': servicesFull
                'pointsToVoteOn':pointsToVoteOn
                'nullOrCachedServices': nullOrCachedServices
              
              popupParcel = setObj.popupParcel
              
              sendParcel(setObj)
            )
          )
      )

  )
  
clearServiceCache = (serviceName) ->
  chrome.storage.local.get('servicesCache', (_r) ->
    
    if !_r.servicesCache? or Object.keys(_r.servicesCache).length is 0 or !_r.servicesCache[serviceName]?
      return false
    else
      delete _r.servicesCache[serviceName]
      
      chrome.storage.local.set({'servicesCache': _r.servicesCache}, ->
        chrome.tabs.getSelected(null,(tab) ->
          setObj = {}
          setObj.msg = 'popupParcel_ready'
          setObj.forUrl = tabUrl
          if popupParcel?
            setObj.popupParcel = popupParcel
            setObj.popupParcel.pointsToVoteOn = popupParcel.servicesFull[serviceName].service.pointsData
            setObj.popupParcel.nullOrCachedServices = _r.servicesCache
            popupParcel = setObj.popupParcel
            sendParcel(setObj)
        )
      )
  )
chrome.extension.onConnect.addListener((port) ->
  
  if port.name is 'fromPopupToBackground'
    
    port.onMessage.addListener( (dataFromPopup) ->
      
      if !dataFromPopup.msg?
        return false
      
      switch dataFromPopup.msg
        
        when 'post_clearService'
          
          clearServiceCache(dataFromPopup.serviceName)
          
        when 'post_userVote'
        
          if dataFromPopup.forUrl is tabUrl
            cacheUserVote(dataFromPopup.userAgreedBool, dataFromPopup.serviceName, dataFromPopup.pointId)
          
          
        when 'request_popupParcel'
          
          popupOpen = true
          
          # console.log 'serviceMatchObj.forUrl is ' + serviceMatchObj.forUrl
          # console.log 'serviceMatchObj.serviceMatch is ' + serviceMatchObj.serviceMatch
          # console.log ' console.debug popupParcel '
          # console.debug popupParcel
          
          # if !serviceMatchObj.forUrl? or !serviceMatchObj.serviceMatch? or !popupParcel?
          #   messageMainView_noServiceMatch()
          # else 
          if tabUrl is serviceMatchObj.forUrl and serviceMatchObj.serviceMatch is false
            messageMainView_noServiceMatch(tabUrl)
            
          else if Object.keys(popupParcel).length > 0 and tabUrl is dataFromPopup.forUrl
            sendObj = 
              'popupParcel': popupParcel 
              'forUrl':tabUrl
              'msg':'popupParcel_ready'
            sendParcel(sendObj)
            
          else if tabUrl is dataFromPopup.forUrl
            sendObj = 
              'msg':'popupParcel_pending'
              'forUrl':tabUrl
            sendParcel(sendObj)
          else
            messageMainView_noServiceMatch(tabUrl)
          
    )
)


reactor = new bReactor()

reactor.registerEvent('deliverServices')

reactor.addEventListener('deliverServices', (ingredientObj) ->  # an ingredient is either services or a service for a url
  
  
  if ingredientObj.forUrl? and ingredientObj.forUrl is tabUrl
    servicesReady(ingredientObj.services,ingredientObj.forUrl)
  
)
    
    
checkIfCurrentVersionOfApiServicePointIsInServicesCache = (serviceApiPointsObject, cachedPoints, pointId) ->
  # console.log 'serviceApiPointsObject'
  # console.debug serviceApiPointsObject
  
  # console.log 'console.debug cachedPoints'
  # console.debug cachedPoints
  
  _i = cachedPoints[pointId].length - 1
  
    # meta check
  if serviceApiPointsObject[pointId].meta? or cachedPoints[pointId][_i].canonical.meta?
    if serviceApiPointsObject[pointId].meta? and cachedPoints[pointId][_i].canonical.meta?
      if !_.isEqual(serviceApiPointsObject[pointId].meta, cachedPoints[pointId][_i].canonical.meta)
        return false
    else
      return false
    
    # source check
  if serviceApiPointsObject[pointId].source? or cachedPoints[pointId][_i].canonical.source?
    if serviceApiPointsObject[pointId].source? and cachedPoints[pointId][_i].canonical.source?
      if !_.isEqual(serviceApiPointsObject[pointId].source, cachedPoints[pointId][_i].canonical.source)
        return false
    else
      return false
    
    # title check
  if serviceApiPointsObject[pointId].title? or cachedPoints[pointId][_i].canonical.title?
    if serviceApiPointsObject[pointId].title? and cachedPoints[pointId][_i].canonical.title?
      if !_.isEqual(serviceApiPointsObject[pointId].title, cachedPoints[pointId][_i].canonical.title)
        return false
    else
      return false
  else if !cachedPoints[pointId][_i].canonical.title?
    return false
    
  if serviceApiPointsObject[pointId].tosdr.tldr? or cachedPoints[pointId][_i].canonical.tldr?
    if serviceApiPointsObject[pointId].tosdr.tldr? and cachedPoints[pointId][_i].canonical.tldr?
      if !_.isEqual(serviceApiPointsObject[pointId].tosdr.tldr, cachedPoints[pointId][_i].canonical.tldr)
        return false
    else
      return false
  else if !cachedPoints[pointId][_i].canonical.tldr?
    return false
  
  return true
  

  
getPointsToVoteOn = (servicesFull, serviceName, callback) ->
  
  service = servicesFull[serviceName].service
  
  serviceApiPointsObject = _.extend {}, service.pointsData
  
  chrome.storage.local.get('servicesCache', (response) ->
    
    
    
    apiPointIds = Object.keys(servicesFull[serviceName].service.pointsData)
    # console.log 'console.debug apiPointIds'
    # console.debug apiPointIds
    if response.servicesCache?
      
      if response.servicesCache[serviceName]?
        # console.log 'console.debug Object.keys(response.servicesCache[serviceName].decisionPoints)'
        # console.debug Object.keys(response.servicesCache[serviceName].decisionPoints)
        
        for pointId, decisionPoint of response.servicesCache[serviceName].decisionPoints
          
          if pointId in apiPointIds
            
            if checkIfCurrentVersionOfApiServicePointIsInServicesCache(serviceApiPointsObject, response.servicesCache[serviceName].decisionPoints, pointId)
              
              delete serviceApiPointsObject[pointId]
              
        callback(serviceApiPointsObject, response.servicesCache)
        
      else
        
        callback(serviceApiPointsObject, response.servicesCache)
        
    else
      callback(serviceApiPointsObject, null)
  )
  

updateBadgeText = (text) ->
  chrome.browserAction.setBadgeText({'text':text.toString()}) 
    

servicesIndexAndServicesFullReady = (servicesIndex, servicesFull, serviceName, forUrl) ->
  
    # get votingHashObject for this service
  
  # console.log 'in servicesIndexAndServicesFullReady'
  # console.log 'console.debug servicesFull'
  # console.debug servicesFull
  
  
  if servicesFull[serviceName]?
    serviceMatchObj =
      forUrl: forUrl
      serviceMatch: true
    
    getPointsToVoteOn( servicesFull, serviceName, (pointsToVoteOn, nullOrCachedServices ) ->
        
        
        # to prevent queries from previous tabs from mixing in with current tab
      if forUrl is tabUrl
        
        # console.log 'console.debug servicesIndex'
        # console.debug servicesIndex
        # console.log 'console.debug servicesFull'
        # console.debug servicesFull
        # console.log 'console.debug serviceName'
        # console.debug serviceName
        # console.log 'console.debug forUrl'
        # console.debug forUrl
        # console.log 'console.debug pointsToVoteOn'
        # console.debug pointsToVoteOn
        
        updateMainViewData(pointsToVoteOn, nullOrCachedServices, servicesFull, serviceName, forUrl)
        
    )
  
  else
    serviceMatchObj =
      forUrl: forUrl
      serviceMatch: false
    
    
  
updateServicesIndex = (currentUrl) ->
  timestamp = Date.now()
  # console.log 'in updateServicesIndex'
  $.ajax('https://tosdr.org/index/services.json', { success: (servicesIndex) ->
    # console.log 'services json: remove from production'
    # console.debug(servicesIndex);
    
     # fixing imperfect naming convention implementations
    if servicesIndex['world-of-warcraft']?
        # not a proper domain name
      delete servicesIndex['world-of-warcraft']
    
    if servicesIndex['microsoft-store']?
        # not a proper domain name
      servicesIndex['microsoftstore'] = servicesIndex['microsoft-store']
      delete servicesIndex['microsoft-store']
    
    if servicesIndex['apple-icloud']?
        # not a proper domain name
      servicesIndex['icloud'] = servicesIndex['apple-icloud']
      delete servicesIndex['apple-icloud']
      
    if servicesIndex['mint.com']?
        # not a proper domain name
      servicesIndex['mint'] = servicesIndex['mint.com']
      delete servicesIndex['mint.com']
      
    serviceNamesArray = Object.keys(servicesIndex)
    
    getVanity = (name) ->
      fragments = name.split('-')
      if fragments.length is 1
        return fragments[0]
      else
        return fragments[fragments.length - 2]  
    
    vanityHash = {}
    
    for name in serviceNamesArray
      vanityHash[getVanity(name)] = name
    
    setObj = 
      vanityHash: vanityHash
      timestamp: timestamp
    
    chrome.storage.local.set({'services': setObj}, (services) ->
      
      reactor.dispatchEvent('deliverServices', {'services':setObj,'forUrl':currentUrl})
      
    )
    
  })
  
updateService = (servicesFullObject = {}, serviceName, currentUrl, callback, servicesIndex = null) ->
  timestamp = Date.now()
  
  # console.log 'end --- update service'
  
  $.getJSON("https://tosdr.org/api/1/service/" + serviceName + ".json").done((serviceFull) ->
    
    setObj = 
      service: serviceFull
      timestamp: timestamp
    
    servicesFullObject[serviceName] = setObj
    
    chrome.storage.local.set({'servicesFull': servicesFullObject}, () ->
      
      if servicesIndex?
        callback(servicesIndex, servicesFullObject, serviceName, currentUrl)
      else
        callback(servicesFullObject, serviceName, currentUrl)
        
    )
  )
  
refreshBadge = (popupParcel) ->
  
  #update badge text
  if Object.keys(popupParcel.pointsToVoteOn).length > 0
    updateBadgeText(Object.keys(popupParcel.pointsToVoteOn).length)
    
  else if popupParcel.nullOrCachedServices[popupParcel.serviceName]? and popupParcel.nullOrCachedServices[popupParcel.serviceName].decisionPoints? and Object.keys(popupParcel.nullOrCachedServices[popupParcel.serviceName].decisionPoints).length > 0
    
    voteYesCount = 0
    totalCount = 0 
    
    for pointName, decisionPointsArray of popupParcel.nullOrCachedServices[popupParcel.serviceName].decisionPoints
      
      if decisionPointsArray[decisionPointsArray.length - 1].voteAgree
        voteYesCount++
      
      totalCount++
      
    updateBadgeText(voteYesCount + '/' + totalCount) 

servicesReady = (servicesIndex, forUrl) ->
  
    # before querying backend for fullService, check if service is in the servicesIndex and not in local storage)
  currentTime = Date.now()
  
  COMfrags = forUrl.split('.com') # until tosdr/eff explicitly say TOS apply to other TLDs (co.uk, .cn, etc - i'll only let a few in)
  
  if forUrl.indexOf('wikipedia.org') != -1
    COMfrags = forUrl.split('.org')
  
  
  if COMfrags.length > 1
    DOTfrags = COMfrags[COMfrags.length - 2].split('.')
    
    domainPreTLD = DOTfrags[DOTfrags.length - 1]
    protocolFRAGS = domainPreTLD.split('//')
    domainName = protocolFRAGS[protocolFRAGS.length - 1]
    # console.log 'console.log domainName'
    # console.log domainName
    
    if servicesIndex.vanityHash[domainName]?
      
      serviceMatchObj =
        forUrl: forUrl
        serviceMatch: true
      
      # chrome.storage.local.get(['servicesFull'], (servicesFullResult) ->
        
      chrome.storage.local.get(null, (allItems) ->
        
        # console.log 'before we update services'
        # console.debug allItems
        
        if allItems['servicesFull']?
          
          if allItems['servicesFull'][servicesIndex.vanityHash[domainName]]? and 
              (currentTime - allItems['servicesFull'][servicesIndex.vanityHash[domainName]].timestamp) < 22100000
            serviceMatchObj =
              forUrl: forUrl
              serviceMatch: true
            servicesIndexAndServicesFullReady(servicesIndex, allItems['servicesFull'], servicesIndex.vanityHash[domainName], forUrl)
            
          else
            
            updateService(allItems['servicesFull'], servicesIndex.vanityHash[domainName], forUrl, servicesIndexAndServicesFullReady, servicesIndex)
        else
          servicesFullObj = {}
          updateService(servicesFullObj, servicesIndex.vanityHash[domainName], forUrl, servicesIndexAndServicesFullReady, servicesIndex)
      )
      
    else
      
      serviceMatchObj =
        forUrl: forUrl
        serviceMatch: false  
      
      if popupOpen
        
        messageMainView_noServiceMatch(tabUrl)
        
  else
      
    serviceMatchObj =
      forUrl: forUrl
      serviceMatch: false  
    
    if popupOpen
      
      messageMainView_noServiceMatch(tabUrl)
      
initialize = (currentUrl) ->
  
  updatesCountTest++
  
  currentTime = Date.now()
  
   # to prevent repeated api requests for services - we check to see if we have an up-to-date version in local storage
  chrome.storage.local.get(null, (allItems) ->
      
    if allItems['services']?
      
      if ((currentTime - allItems['services'].timestamp) < 86400000)
      
        updateServicesIndex(currentUrl)
      
      else
        
        reactor.dispatchEvent('deliverServices', {'services':services,'forUrl':currentUrl})
      
    else
    
      updateServicesIndex(currentUrl)
      
  )

initIfNewURL = ->
  
  popupOpen = false
  
  chrome.tabs.getSelected(null,(tab) ->
      
    chrome.storage.local.get('persistentUrl', (data) -> #useful for switching window contexts
      
      if data.persistentUrl != tab.url
        
        updateBadgeText('')
        
        chrome.storage.local.set({'persistentUrl': tab.url}, ->)
        
      currentUrl = tab.url
    
      if ( document.readyState != 'complete' and currentUrl != tabUrl)
        tabUrl = currentUrl
        
        $(document).ready( -> 
          
          initialize(currentUrl) 
        )
        
      else if (currentUrl != tabUrl)
        tabUrl = currentUrl
        initialize(currentUrl)
         
    )
  )

chrome.tabs.onActivated.addListener( initIfNewURL )

chrome.tabs.onUpdated.addListener( initIfNewURL )

chrome.windows.onFocusChanged.addListener( initIfNewURL )


