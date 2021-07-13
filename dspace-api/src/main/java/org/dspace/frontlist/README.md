# FrontList Consumer Configuration
## Why Frontlist Consumer is needed.
 We do not want to show  private and empty collections to non-admin users.
Only those users who can administrate private or empty collections or can submit to those collections, will see them. 
It proved to be too resource intensive to calculate on the fly which communities and collection a specific user should see.
 
 To reduce the amount of calculations we do most calculations on the application startup. To initiate the calculation
 we added a method call to `DSpaceContextListener` servlet
On the start up we initialize 4 static ConcurrentHashMaps objects:

- Map of communities and collections for site admins `colMapAdmin,comMapAdmin`
- Map of communities and collections for all non-admin users `colMapAnon,comMapAnon`

Each entry in maps for collections has parent community id as a key and array of children collections as a value
          `< Parent Community ID, [array of collections]>`
          
Each entry in maps for communities has parent community id as a key and array of children subcommunties as a value
          `< Parent Community ID, [array of subcommunties]>`
         
As we have a limited number of  users who can get access to specific private and empty collections,for those users 
we will add communities and collections on the fly.On the application start up we pre-calculate the list of those users and keep them in 2 static 
CopyOnWriteArrayLists (we use this type to avoid concurrency issues):
`colAuthorizedUsers` and `commAuthorizedUsers`.

Each item in `colAuthorizedUsers` list is an object of custom type `AuthorizedCollectionUsers`. 
The type has the triple of attributes  `<eperson ID, group ID, collection ID>`
          
Each item in `commAuthorizedUsers` is an object of custom type `AuthorizedCollectionUsers`. 
The type has the triple of attributes `<eperson ID, group ID, community ID>`
          
Also we pre-calculate 4 objects of CopyOnWriteArrayLists `nyuOnly`, `gallatinOnly`, `emptyCollections`, `privateCollections`
All those objects are used by the following classes  
- `ListCommunitiesSiteProcessor` which generates site home page (objects will be passed to home.jsp as attributes)
- `ListCommunitiescomminityProcessor` which generates community home page (objects will be passed to community-home.jsp as attributes)
- `ComminityListServlet` which generates communities and collection lists (objects will be passed to community-list.jsp as attributes)
          
As we make all the initial calculations when the application starts we need to update the maps and lists when the following changes are made during the application
lifecycle:
- When items are added to empty collection,
- When all items are removed from collection,
- When new admins or submitters are added or removed for private or empty collections,
- When collection permissions are modified,
- When collections and communities are added or removed
- when collection and community metadata is modified
          
 We use this class to consume the information of the events listed above and trigger 
 the appropriate calculations. There is no event for modification in collection/community policy,
 so we added collection status check to  `AuthorizeAdminServlet` where collection policy is changed.
 We also assumed that we won't be changing community policies.
 More information about DSpace event processing system you can find [here](.https://wiki.lyrasis.org/display/DSPACE/EventSystemPrototype)
 
 ## Changes in the configuration file dspace.cfg
 
 - To add new processing plugins for home and community pages
 
   `plugin.sequence.org.dspace.plugin.SiteHomeProcessor = \
    org.dspace.app.webui.components.TopCommunitiesSiteProcessor,\
        org.dspace.app.webui.components.ListCommunitiesSiteProcessor,\
        org.dspace.app.webui.components.MostDownloadedSite,\
        org.dspace.app.webui.discovery.SideBarFacetProcessor`
  
    `plugin.sequence.org.dspace.plugin.CommunityHomeProcessor = \
        org.dspace.app.webui.components.ListCommunitiesCommunityProcessor,\
        org.dspace.app.webui.components.MostDownloadedCommunity,\
        org.dspace.app.webui.discovery.SideBarFacetProcessor`      
 
 - To add front list consumer for processing events
   
   `# consumer to update hash lists of communities and collections
    event.consumer.frontlist.class = org.dspace.frontlist.FrontListEventConsumer
    event.consumer.frontlist.filters = Site!Community|Collection|Group|Item+Add|Remove|Delete|Create|Modify_Metadata|Modify`
  
   `event.dispatcher.default.consumers = versioning, discovery, eperson, harvester,frontlist`
 
 - To not allow community admins to delete sub-communities and collections and modify community 
 collection

   `core.authorization.community-admin.create-subelement = true`

   `core.authorization.community-admin.delete-subelement = false`

   `core.authorization.community-admin.policies = false`

   `core.authorization.community-admin.collection.policies = false`
 
 - To not allow collection admins to modify collection policies 
  
   `core.authorization.collection-admin.policies = false` 