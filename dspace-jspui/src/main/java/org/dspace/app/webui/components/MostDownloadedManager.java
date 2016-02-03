package org.dspace.app.webui.components;

import com.google.gson.JsonArray;
import org.apache.jena.atlas.json.*;
import org.apache.jena.atlas.json.JsonObject;
import org.apache.log4j.Logger;

import org.dspace.content.DSpaceObject;
import org.dspace.content.Item;
import org.dspace.core.Context;
import org.dspace.core.Constants;
import org.dspace.core.ConfigurationManager;

import com.google.gson.*;

import java.net.URLConnection;
import java.net.URL;
import java.sql.SQLException;
import java.util.List;

import org.apache.commons.io.*;
import org.dspace.discovery.*;
import org.dspace.discovery.configuration.DiscoveryConfigurationParameters;


/**
 * Created by katepechekhonova on 2/1/16.
 */
public class MostDownloadedManager {
    /**
     * logger
     */
    private static Logger log = Logger.getLogger(RecentSubmissionsManager.class);

    /**
     * DSpace context
     */
    private Context context;

    /**
     * Construct a new MostDownloadedManager with the given DSpace context
     *
     * @param context
     */
    public MostDownloadedManager(Context context) {
        this.context = context;
    }

    /**
     * Obtain the most downloaded items from the given container object.  This
     * method uses the configuration to determine which field and how many
     * items to retrieve from the DSpace Object.
     * <p>
     * If the object you pass in is not a Community or Collection (e.g. an Item
     * is a DSpaceObject which cannot be used here), an exception will be thrown
     *
     * @param dso DSpaceObject: Community, Collection or null for SITE
     * @throws MostDownloadedException
     * @return The most downloadable items
     */
    public MostDownloaded getMostDownloaded(DSpaceObject dso)
            throws MostDownloadedException {
        int count = 10;

        Item[] items = new Item[count];

        try {


            SolrStatisticsServiceImpl solr = new SolrStatisticsServiceImpl();

            DiscoverQuery dq = new DiscoverQuery();

            String queryString="type:0 AND bundleName:ORIGINAL";
            if(dso!=null) {
                if(dso.getType()==Constants.COMMUNITY) {
                    queryString +=" AND owningComm:"+dso.getID();
                }
                if(dso.getType()==Constants.COLLECTION) {
                    queryString +=" AND owningColl:"+dso.getID();
                }
            }

            dq.setQuery(queryString);
            dq.addFacetField(new DiscoverFacetField("owningItem",
                    DiscoveryConfigurationParameters.TYPE_STANDARD, 10, DiscoveryConfigurationParameters.SORT.VALUE));

            DiscoverResult dr = solr.search(context, dq);


            log.error("query: " + dr.getDspaceObjects().get(0).getParentObject());
            log.error("facet: " + dr.getFacetResult("owningItem").get(0).getSortValue());

            List<DiscoverResult.FacetResult> facetFields = dr.getFacetResult("owningItem");


            if (0 < facetFields.size()) {
                //Only add facet information if there are any facets
                int i=0;
                for (DiscoverResult.FacetResult facetField : facetFields) {
                    int itemID=new Integer(facetField.getSortValue());
                    Item item=Item.find(context, itemID);
                    items[i]=item;
                    i++;
                }


            }

        } catch (SQLException e) {
            e.printStackTrace();
        } catch (SearchServiceException e) {
            e.printStackTrace();
        }

    return new MostDownloaded(items);
}
}