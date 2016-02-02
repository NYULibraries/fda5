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
import org.apache.commons.io.*;



/**
 * Created by katepechekhonova on 2/1/16.
 */
public class MostDownloadedManager {
    /** logger */
    private static Logger log = Logger.getLogger(RecentSubmissionsManager.class);

    /** DSpace context */
    private Context context;

    /**
     * Construct a new MostDownloadedManager with the given DSpace context
     *
     * @param context
     */
    public MostDownloadedManager(Context context)
    {
        this.context = context;
    }

    /**
     * Obtain the most downloaded items from the given container object.  This
     * method uses the configuration to determine which field and how many
     * items to retrieve from the DSpace Object.
     *
     * If the object you pass in is not a Community or Collection (e.g. an Item
     * is a DSpaceObject which cannot be used here), an exception will be thrown
     *
     * @param dso	DSpaceObject: Community, Collection or null for SITE
     * @return		The most downloadable items
     * @throws MostDownloadedException
     */
    public MostDownloaded getMostDownloaded(DSpaceObject dso)
            throws MostDownloadedException
    {
        try
        {
            // get our configuration
            //String count = ConfigurationManager.getProperty("most.downloaded.count");

            int count = 10;
            JsonObject json=new JsonObject();

            String urlString = ConfigurationManager.getProperty("dspace.baseUrl")+"/solr/statistics/select?start=0&rows=10&fl=*%2Cscore&qt=standard&wt=json&" +
                    "explainOther=&hl.fl=&facet=true&facet.field=owningItem&q=type:0%20AND%20bundleName:ORIGINAL";
            if(dso!=null) {
                if (dso.getType() == Constants.COMMUNITY) {
                    urlString += "%20AND%20owningComm:" + dso.getID();
                }
                if (dso.getType() == Constants.COLLECTION) {
                    urlString += "%20AND%20owningColl:" + dso.getID();
                }
            }
            try {

                URL url = new URL(urlString);
                URLConnection conn = url.openConnection();
                String theString = IOUtils.toString(conn.getInputStream(), "UTF-8");
                log.error("query: "+theString);
                json= JSON.parse(theString);


            } catch (Exception e) {
                e.printStackTrace();
            }


            Item[] items=new Item[count];
            int j=0;

            org.apache.jena.atlas.json.JsonArray itemIDs=json.get("facet_counts").getAsObject().get("facet_fields").getAsObject().get("owningItem").getAsArray();
            for (int i = 0; i < itemIDs.size()/2; i++) {

                 int itemID=Integer.parseInt(itemIDs.get(j).getAsString().value());
                 //if ((int) itemIDs.get(j).getAsNumber().value()>0)
                 items[i]=Item.find(context,itemID);
                 j=j+2;
            }

            return new MostDownloaded(items);
        }

        catch (Exception e) {
            log.error("caught exception: ", e);
            throw new MostDownloadedException(e);
        }
    }

}
