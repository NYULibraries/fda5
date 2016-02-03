package org.dspace.discovery;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.collections.MapUtils;
import org.apache.commons.collections.Transformer;
import org.apache.commons.lang.ArrayUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.time.DateFormatUtils;
import org.apache.commons.validator.routines.UrlValidator;
import org.apache.http.HttpHost;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.params.ClientPNames;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.log4j.Logger;
import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.request.AbstractUpdateRequest;
import org.apache.solr.client.solrj.request.ContentStreamUpdateRequest;
import org.apache.solr.client.solrj.response.FacetField;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.client.solrj.util.ClientUtils;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrDocumentList;
import org.apache.solr.common.SolrInputDocument;
import org.apache.solr.common.params.*;
import org.apache.solr.common.util.NamedList;
import org.apache.solr.handler.extraction.ExtractingParams;
import org.dspace.content.*;
import org.dspace.content.Collection;
import org.dspace.content.authority.ChoiceAuthorityManager;
import org.dspace.content.authority.Choices;
import org.dspace.content.authority.MetadataAuthorityManager;
import org.dspace.core.*;
import org.dspace.discovery.configuration.*;
import org.dspace.handle.HandleManager;
import org.dspace.storage.rdbms.DatabaseUtils;
import org.dspace.util.MultiFormatDateParser;
import org.dspace.utils.DSpace;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.URI;
import java.net.URISyntaxException;
import java.sql.SQLException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Created by katepechekhonova on 2/2/16.
 */
public class SolrStatisticsServiceImpl  extends SolrServiceImpl {

    protected HttpSolrServer solr = null;

    private static final Logger log = Logger.getLogger(SolrStatisticsServiceImpl.class);

    protected static final String RESOURCE_TYPE_FIELD = "type";
    protected static final String RESOURCE_ID_FIELD = "id";

    public static final String FILTER_SEPARATOR = "\n|||\n";


    protected HttpSolrServer getSolr() {

        if (solr == null) {
            //String solrService = new DSpace().getConfigurationService().getProperty("dspace.base.url")+"/solr/statistics";
            String solrService = "http://localhost:8080/solr/statistics";
            UrlValidator urlValidator = new UrlValidator(UrlValidator.ALLOW_LOCAL_URLS);
            if (urlValidator.isValid(solrService) || ConfigurationManager.getBooleanProperty("discovery", "solr.url.validation.enabled", true)) {
                try {
                    log.debug("Solr URL: " + solrService);
                    solr = new HttpSolrServer(solrService);

                    solr.setBaseURL(solrService);
                    solr.setUseMultiPartPost(true);


                } catch (Exception e) {
                    log.error("Error while initializing solr server", e);
                }
            } else {
                log.error("Error while initializing solr, invalid url: " + solrService);
            }
        }

        return solr;
    }

    //******** SearchService implementation
    @Override
    public DiscoverResult search(Context context, DiscoverQuery query) throws SearchServiceException {
        return search(context, query, false);
    }

    @Override
    public DiscoverResult search(Context context, DSpaceObject dso,
                                 DiscoverQuery query)
            throws SearchServiceException {
        return search(context, dso, query, false);
    }

    public DiscoverResult search(Context context, DSpaceObject dso, DiscoverQuery discoveryQuery, boolean includeUnDiscoverable) throws SearchServiceException {
        if (dso != null) {
            if (dso instanceof Community) {
                discoveryQuery.addFilterQueries("location:m" + dso.getID());
            } else if (dso instanceof Collection) {
                discoveryQuery.addFilterQueries("location:l" + dso.getID());
            }
        }
        return search(context, discoveryQuery, includeUnDiscoverable);

    }


    public DiscoverResult search(Context context, DiscoverQuery discoveryQuery, boolean includeUnDiscoverable) throws SearchServiceException {
        try {
            if (getSolr() == null) {
                return new DiscoverResult();
            }
            SolrQuery solrQuery = resolveToSolrQuery(context, discoveryQuery, includeUnDiscoverable);


            QueryResponse queryResponse = getSolr().query(solrQuery);
            return retrieveResult(context, discoveryQuery, queryResponse);

        } catch (Exception e) {
            throw new org.dspace.discovery.SearchServiceException(e.getMessage(), e);
        }
    }

    protected SolrQuery resolveToSolrQuery(Context context, DiscoverQuery discoveryQuery, boolean includeUnDiscoverable) {
        SolrQuery solrQuery = new SolrQuery();

        String query = "*:*";
        if (discoveryQuery.getQuery() != null) {
            query = discoveryQuery.getQuery();
        }

        solrQuery.setQuery(query);

        // Add any search fields to our query. This is the limited list
        // of fields that will be returned in the solr result
        for (String fieldName : discoveryQuery.getSearchFields()) {
            solrQuery.addField(fieldName);
        }
        solrQuery.addField(RESOURCE_TYPE_FIELD);
        solrQuery.addField(RESOURCE_ID_FIELD);
        solrQuery.addField("owningItem");


        for (int i = 0; i < discoveryQuery.getFilterQueries().size(); i++) {
            String filterQuery = discoveryQuery.getFilterQueries().get(i);
            solrQuery.addFilterQuery(filterQuery);
        }
        if (discoveryQuery.getDSpaceObjectFilter() != -1) {
            solrQuery.addFilterQuery(RESOURCE_TYPE_FIELD + ":" + discoveryQuery.getDSpaceObjectFilter());
        }


        if (discoveryQuery.getStart() != -1) {
            solrQuery.setStart(discoveryQuery.getStart());
        }

        if (discoveryQuery.getMaxResults() != -1) {
            solrQuery.setRows(discoveryQuery.getMaxResults());
        }

        if (discoveryQuery.getSortField() != null) {
            SolrQuery.ORDER order = SolrQuery.ORDER.asc;
            if (discoveryQuery.getSortOrder().equals(DiscoverQuery.SORT_ORDER.desc))
                order = SolrQuery.ORDER.desc;

            solrQuery.addSortField(discoveryQuery.getSortField(), order);
        }

        for (String property : discoveryQuery.getProperties().keySet()) {
            List<String> values = discoveryQuery.getProperties().get(property);
            solrQuery.add(property, values.toArray(new String[values.size()]));
        }

        List<DiscoverFacetField> facetFields = discoveryQuery.getFacetFields();
        if (0 < facetFields.size()) {
            //Only add facet information if there are any facets
            log.error("field:"+facetFields.get(0));
            for (DiscoverFacetField facetFieldConfig : facetFields) {
                String field = transformFacetField(facetFieldConfig, facetFieldConfig.getField(), false);
                solrQuery.addFacetField(field);
                log.error("field:"+solrQuery.getFacetFields()[0]);
                // Setting the facet limit in this fashion ensures that each facet can have its own max
                solrQuery.add("f." + field + "." + FacetParams.FACET_LIMIT, String.valueOf(facetFieldConfig.getLimit()));
                String facetSort;
                if (DiscoveryConfigurationParameters.SORT.COUNT.equals(facetFieldConfig.getSortOrder())) {
                    facetSort = FacetParams.FACET_SORT_COUNT;
                } else {
                    facetSort = FacetParams.FACET_SORT_INDEX;
                }
                solrQuery.add("f." + field + "." + FacetParams.FACET_SORT, facetSort);

            }

            List<String> facetQueries = discoveryQuery.getFacetQueries();
            for (String facetQuery : facetQueries) {
                solrQuery.addFacetQuery(facetQuery);
            }

            if (discoveryQuery.getFacetMinCount() != -1) {
                solrQuery.setFacetMinCount(discoveryQuery.getFacetMinCount());
            }

        }

        return solrQuery;
    }

    @Override
    public InputStream searchJSON(Context context, DiscoverQuery query, DSpaceObject dso, String jsonIdentifier) throws SearchServiceException {
        if (dso != null) {
            if (dso instanceof Community) {
                query.addFilterQueries("location:m" + dso.getID());
            } else if (dso instanceof Collection) {
                query.addFilterQueries("location:l" + dso.getID());
            }
        }
        return searchJSON(context, query, jsonIdentifier);
    }


    public InputStream searchJSON(Context context, DiscoverQuery discoveryQuery, String jsonIdentifier) throws SearchServiceException {
        if (getSolr() == null) {
            return null;
        }

        SolrQuery solrQuery = resolveToSolrQuery(context, discoveryQuery, false);
        //We use json as out output type
        solrQuery.setParam("json.nl", "map");
        solrQuery.setParam("json.wrf", jsonIdentifier);
        solrQuery.setParam(CommonParams.WT, "json");

        StringBuilder urlBuilder = new StringBuilder();
        urlBuilder.append(getSolr().getBaseURL()).append("/select?");
        urlBuilder.append(solrQuery.toString());

        try {
            HttpGet get = new HttpGet(urlBuilder.toString());
            HttpResponse response = new DefaultHttpClient().execute(get);
            return response.getEntity().getContent();

        } catch (Exception e) {
            log.error("Error while getting json solr result for discovery search recommendation", e);
        }
        return null;
    }

    protected DiscoverResult retrieveResult(Context context, DiscoverQuery query, QueryResponse solrQueryResponse) throws SQLException {
        DiscoverResult result = new DiscoverResult();

        if (solrQueryResponse != null) {
            result.setSearchTime(solrQueryResponse.getQTime());
            result.setStart(query.getStart());
            result.setMaxResults(query.getMaxResults());
            result.setTotalSearchResults(solrQueryResponse.getResults().getNumFound());

            List<String> searchFields = query.getSearchFields();
            for (SolrDocument doc : solrQueryResponse.getResults()) {
                DSpaceObject dso = findDSpaceObject(context, doc);

                if (dso != null) {
                    result.addDSpaceObject(dso);
                } else {
                    log.error(LogManager.getHeader(context, "Error while retrieving DSpace object from discovery index", "ID: " + doc.getFirstValue("type")));
                    continue;
                }

                DiscoverResult.SearchDocument resultDoc = new DiscoverResult.SearchDocument();
                //Add information about our search fields
                for (String field : searchFields) {
                    List<String> valuesAsString = new ArrayList<String>();
                    for (Object o : doc.getFieldValues(field)) {
                        valuesAsString.add(String.valueOf(o));
                    }
                    resultDoc.addSearchField(field, valuesAsString.toArray(new String[valuesAsString.size()]));
                }
                result.addSearchDocument(dso, resultDoc);


            }

            //Resolve our facet field values
            List<FacetField> facetFields = solrQueryResponse.getFacetFields();
            if (facetFields != null) {
                for (int i = 0; i < facetFields.size(); i++) {
                    FacetField facetField = facetFields.get(i);
                    DiscoverFacetField facetFieldConfig = query.getFacetFields().get(i);
                    List<FacetField.Count> facetValues = facetField.getValues();

                    for (FacetField.Count facetValue : facetValues)
                    {
                        String displayedValue = transformDisplayedValue(context, facetField.getName(), facetValue.getName());
                        String field = transformFacetField(facetFieldConfig, facetField.getName(), true);
                        String authorityValue = transformAuthorityValue(context, facetField.getName(), facetValue.getName());
                        String sortValue = transformSortValue(context, facetField.getName(), facetValue.getName());
                        String filterValue = displayedValue;
                        if (StringUtils.isNotBlank(authorityValue))
                        {
                            filterValue = authorityValue;
                        }
                        result.addFacetResult(
                                field,
                                new DiscoverResult.FacetResult(filterValue,
                                        displayedValue, authorityValue,
                                        sortValue, facetValue.getCount()));
                    }
                }
            }
        }




        return result;
    }

    protected static DSpaceObject findDSpaceObject(Context context, SolrDocument doc) throws SQLException {

        Integer type = (Integer) doc.getFirstValue(RESOURCE_TYPE_FIELD);
        Integer id = (Integer) doc.getFirstValue(RESOURCE_ID_FIELD);

        if (type != null && id != null) {
            return DSpaceObject.find(context, type, id);
        }

        return null;
    }


    public static String locationToName(Context context, String field, String value) throws SQLException {
        if("location.comm".equals(field) || "location.coll".equals(field))
        {
            int type = field.equals("location.comm") ? Constants.COMMUNITY : Constants.COLLECTION;
            DSpaceObject commColl = DSpaceObject.find(context, type, Integer.parseInt(value));
            if(commColl != null)
            {
                return commColl.getName();
            }

        }
        return value;
    }
    /**
     * Simple means to return the search result as an InputStream
     */
    public java.io.InputStream searchAsInputStream(DiscoverQuery query) throws SearchServiceException, java.io.IOException {
        if (getSolr() == null) {
            return null;
        }
        HttpHost hostURL = (HttpHost) (getSolr().getHttpClient().getParams().getParameter(ClientPNames.DEFAULT_HOST));

        HttpGet method = new HttpGet(hostURL.toHostString() + "");
        try {
            URI uri = new URIBuilder(method.getURI()).addParameter("q", query.toString()).build();
        } catch (URISyntaxException e) {
            throw new SearchServiceException(e);
        }

        HttpResponse response = getSolr().getHttpClient().execute(method);

        return response.getEntity().getContent();
    }

    public List<DSpaceObject> search(Context context, String query, int offset, int max, String... filterquery) {
        return search(context, query, null, true, offset, max, filterquery);
    }

    public List<DSpaceObject> search(Context context, String query, String orderfield, boolean ascending, int offset, int max, String... filterquery) {

        try {
            if (getSolr() == null) {
                return Collections.emptyList();
            }

            SolrQuery solrQuery = new SolrQuery();
            solrQuery.setQuery(query);
            //Only return obj identifier fields in result doc
            solrQuery.setFields(RESOURCE_ID_FIELD, RESOURCE_TYPE_FIELD);
            solrQuery.setStart(offset);
            solrQuery.setRows(max);
            if (orderfield != null) {
                solrQuery.setSortField(orderfield, ascending ? SolrQuery.ORDER.asc : SolrQuery.ORDER.desc);
            }
            if (filterquery != null) {
                solrQuery.addFilterQuery(filterquery);
            }
            QueryResponse rsp = getSolr().query(solrQuery);
            SolrDocumentList docs = rsp.getResults();

            Iterator iter = docs.iterator();
            List<DSpaceObject> result = new ArrayList<DSpaceObject>();
            while (iter.hasNext()) {
                SolrDocument doc = (SolrDocument) iter.next();

                DSpaceObject o = DSpaceObject.find(context, (Integer) doc.getFirstValue(RESOURCE_TYPE_FIELD), (Integer) doc.getFirstValue(RESOURCE_ID_FIELD));

                if (o != null) {
                    result.add(o);
                }
            }
            return result;
        } catch (Exception e) {
            // Any acception that we get ignore it.
            // We do NOT want any crashed to shown by the user
            log.error(LogManager.getHeader(context, "Error while quering solr", "Queyr: " + query), e);
            return new ArrayList<DSpaceObject>(0);
        }
    }

    public DiscoverFilterQuery toFilterQuery(Context context, String field, String operator, String value) throws SQLException {
        DiscoverFilterQuery result = new DiscoverFilterQuery();

        StringBuilder filterQuery = new StringBuilder();
        if (StringUtils.isNotBlank(field)) {
            filterQuery.append(field);
            if ("equals".equals(operator)) {
                //Query the keyword indexed field !
                filterQuery.append("_keyword");
            } else if ("authority".equals(operator)) {
                //Query the authority indexed field !
                filterQuery.append("_authority");
            } else if ("notequals".equals(operator)
                    || "notcontains".equals(operator)
                    || "notauthority".equals(operator)) {
                filterQuery.insert(0, "-");
            }
            filterQuery.append(":");
            if ("equals".equals(operator) || "notequals".equals(operator)) {
                //DO NOT ESCAPE RANGE QUERIES !
                if (!value.matches("\\[.*TO.*\\]")) {
                    value = ClientUtils.escapeQueryChars(value);
                    filterQuery.append(value);
                } else {
                    if (value.matches("\\[\\d{1,4} TO \\d{1,4}\\]")) {
                        int minRange = Integer.parseInt(value.substring(1, value.length() - 1).split(" TO ")[0]);
                        int maxRange = Integer.parseInt(value.substring(1, value.length() - 1).split(" TO ")[1]);
                        value = "[" + String.format("%04d", minRange) + " TO " + String.format("%04d", maxRange) + "]";
                    }
                    filterQuery.append(value);
                }
            } else {
                //DO NOT ESCAPE RANGE QUERIES !
                if (!value.matches("\\[.*TO.*\\]")) {
                    value = ClientUtils.escapeQueryChars(value);
                    filterQuery.append("(").append(value).append(")");
                } else {
                    filterQuery.append(value);
                }
            }


        }

        result.setFilterQuery(filterQuery.toString());
        return result;
    }

    @Override
    public List<Item> getRelatedItems(Context context, Item item, DiscoveryMoreLikeThisConfiguration mltConfig) {
        List<Item> results = new ArrayList<Item>();
        try {
            SolrQuery solrQuery = new SolrQuery();
            //Set the query to handle since this is unique

            //Only return obj identifier fields in result doc
            solrQuery.setFields(RESOURCE_TYPE_FIELD, RESOURCE_ID_FIELD);
            //Add the more like this parameters !
            solrQuery.setParam(MoreLikeThisParams.MLT, true);
            //Add a comma separated list of the similar fields
            @SuppressWarnings("unchecked")
            java.util.Collection<String> similarityMetadataFields = CollectionUtils.collect(mltConfig.getSimilarityMetadataFields(), new Transformer() {
                @Override
                public Object transform(Object input) {
                    //Add the mlt appendix !
                    return input + "_mlt";
                }
            });

            solrQuery.setParam(MoreLikeThisParams.SIMILARITY_FIELDS, StringUtils.join(similarityMetadataFields, ','));
            solrQuery.setParam(MoreLikeThisParams.MIN_TERM_FREQ, String.valueOf(mltConfig.getMinTermFrequency()));
            solrQuery.setParam(MoreLikeThisParams.DOC_COUNT, String.valueOf(mltConfig.getMax()));
            solrQuery.setParam(MoreLikeThisParams.MIN_WORD_LEN, String.valueOf(mltConfig.getMinWordLength()));

            if (getSolr() == null) {
                return Collections.emptyList();
            }
            QueryResponse rsp = getSolr().query(solrQuery);
            NamedList mltResults = (NamedList) rsp.getResponse().get("moreLikeThis");
            if (mltResults != null && mltResults.get(item.getType() + "-" + item.getID()) != null) {
                SolrDocumentList relatedDocs = (SolrDocumentList) mltResults.get(item.getType() + "-" + item.getID());
                for (Object relatedDoc : relatedDocs) {
                    SolrDocument relatedDocument = (SolrDocument) relatedDoc;
                    DSpaceObject relatedItem = findDSpaceObject(context, relatedDocument);
                    if (relatedItem.getType() == Constants.ITEM) {
                        results.add((Item) relatedItem);
                    }
                }
            }


        } catch (Exception e) {
            log.error(LogManager.getHeader(context, "Error while retrieving related items", "Handle: " + item.getHandle()), e);
        }
        return results;
    }

    @Override
    public String toSortFieldIndex(String metadataField, String type) {
        if (type.equals(DiscoveryConfigurationParameters.TYPE_DATE)) {
            return metadataField + "_dt";
        } else {
            return metadataField + "_sort";
        }
    }

    protected String transformSortValue(Context context, String field, String value) throws SQLException {
        if(field.equals("location.comm") || field.equals("location.coll"))
        {
            value = locationToName(context, field, value);
        }
        else if (field.endsWith("_filter") || field.endsWith("_ac")
                || field.endsWith("_acid"))
        {
            //We have a filter make sure we split !
            String separator = new DSpace().getConfigurationService().getProperty("discovery.solr.facets.split.char");
            if(separator == null)
            {
                separator = FILTER_SEPARATOR;
            }
            //Escape any regex chars
            separator = java.util.regex.Pattern.quote(separator);
            String[] fqParts = value.split(separator);
            StringBuffer valueBuffer = new StringBuffer();
            int end = fqParts.length / 2;
            for(int i = 0; i < end; i++)
            {
                valueBuffer.append(fqParts[i]);
            }
            value = valueBuffer.toString();
        }else if(value.matches("\\((.*?)\\)"))
        {
            //The brackets where added for better solr results, remove the first & last one
            value = value.substring(1, value.length() -1);
        }
        return value;
    }

    protected String transformFacetField(DiscoverFacetField facetFieldConfig, String field, boolean removePostfix) {
        if (facetFieldConfig.getType().equals(DiscoveryConfigurationParameters.TYPE_TEXT)) {
            if (removePostfix) {
                return field.substring(0, field.lastIndexOf("_filter"));
            } else {
                return field + "_filter";
            }
        } else if (facetFieldConfig.getType().equals(DiscoveryConfigurationParameters.TYPE_DATE)) {
            if (removePostfix) {
                return field.substring(0, field.lastIndexOf(".year"));
            } else {
                return field + ".year";
            }
        } else if (facetFieldConfig.getType().equals(DiscoveryConfigurationParameters.TYPE_AC)) {
            if (removePostfix) {
                return field.substring(0, field.lastIndexOf("_ac"));
            } else {
                return field + "_ac";
            }
        } else if (facetFieldConfig.getType().equals(DiscoveryConfigurationParameters.TYPE_HIERARCHICAL)) {
            if (removePostfix) {
                return StringUtils.substringBeforeLast(field, "_tax_");
            } else {
                //Only display top level filters !
                return field + "_tax_0_filter";
            }
        } else if (facetFieldConfig.getType().equals(DiscoveryConfigurationParameters.TYPE_AUTHORITY)) {
            if (removePostfix) {
                return field.substring(0, field.lastIndexOf("_acid"));
            } else {
                return field + "_acid";
            }
        } else if (facetFieldConfig.getType().equals(DiscoveryConfigurationParameters.TYPE_STANDARD)) {
            return field;
        } else {
            return field;
        }
    }

    @Override
    public String escapeQueryChars(String query) {
        // Use Solr's built in query escape tool
        // WARNING: You should only escape characters from user entered queries,
        // otherwise you may accidentally BREAK field-based queries (which often
        // rely on special characters to separate the field from the query value)
        return ClientUtils.escapeQueryChars(query);
    }

}