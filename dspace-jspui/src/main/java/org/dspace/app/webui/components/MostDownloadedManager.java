package org.dspace.app.webui.components;

import com.google.gson.JsonArray;
import org.apache.jena.atlas.json.*;
import org.apache.jena.atlas.json.JsonObject;
import org.apache.log4j.Logger;

import org.dspace.authorize.AuthorizeManager;
import org.dspace.content.DSpaceObject;
import org.dspace.content.Item;
import org.dspace.core.Context;
import org.dspace.core.Constants;
import org.dspace.core.ConfigurationManager;

import com.google.gson.*;

import java.net.URLConnection;
import java.net.URL;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.io.*;
import org.dspace.discovery.*;
import org.dspace.discovery.configuration.DiscoveryConfigurationParameters;
import org.dspace.utils.DSpace;


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
        int count = new Integer(new DSpace().getConfigurationService().
                getProperty("most.downloaded.count"));


        List<DiscoverResult.FacetResult> facetFields=null;

        try {


            SolrStatisticsServiceImpl solr = new SolrStatisticsServiceImpl();

            DiscoverQuery dq = new DiscoverQuery();

            String queryString="type:0 AND bundleName:ORIGINAL";
            if(dso!=null) {
                if(!AuthorizeManager.isAdmin(context, dso)) {
                    queryString += " AND isPublic:true";
                }
                if(dso.getType()==Constants.COMMUNITY) {
                    queryString +=" AND owningComm:"+dso.getID();
                }
                if(dso.getType()==Constants.COLLECTION) {
                    queryString += " AND owningColl:" + dso.getID();
                }
            } else {
                queryString +=" AND isPublic:true";
            }

            dq.setQuery(queryString);
            dq.setFacetMinCount(1);
            dq.addFacetField(new DiscoverFacetField("owningItem",
                    DiscoveryConfigurationParameters.TYPE_STANDARD, count, DiscoveryConfigurationParameters.SORT.VALUE));

            DiscoverResult dr = solr.search(context, dq);

            facetFields = dr.getFacetResult("owningItem");

            List<Item> itemsList = new ArrayList<Item>();

            if (facetFields!=null&&facetFields.size()>0) {
                for (DiscoverResult.FacetResult facetField : facetFields) {
                    int itemID=new Integer(facetField.getSortValue());
                    Item item=Item.find(context, itemID);
                    if(item!=null)  {
                        itemsList.add(item);
                    }
                }
                if(itemsList!=null) {
                    Item[] items=new Item[itemsList.size()];
                    items =  itemsList.toArray(items);
                    return new MostDownloaded(items);
                } else {
                    return null;
                }
            }
            else
            {
                return null;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        } catch (SearchServiceException e) {
            e.printStackTrace();
        }

    return null;
}
}