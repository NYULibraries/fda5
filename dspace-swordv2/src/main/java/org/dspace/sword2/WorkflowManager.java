/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.sword2;

import org.dspace.content.Bitstream;
import org.dspace.content.Collection;
import org.dspace.content.Item;
import org.dspace.core.Context;
import org.swordapp.server.Deposit;
import org.swordapp.server.SwordError;

public interface WorkflowManager
{
	void retrieveServiceDoc(Context context) throws SwordError, DSpaceSwordException;

	void listCollectionContents(Context context, Collection collection) throws SwordError, DSpaceSwordException;

	void createResource(Context context, Collection collection) throws SwordError, DSpaceSwordException;

	void retrieveContent(Context context, Item item) throws SwordError, DSpaceSwordException;

	void retrieveBitstream(Context context, Bitstream bitstream) throws SwordError, DSpaceSwordException;

	void replaceResourceContent(Context context, Item item) throws SwordError, DSpaceSwordException;

    void replaceBitstream(Context context, Bitstream bitstream) throws SwordError, DSpaceSwordException;

	void replaceMetadata(Context context, Item item) throws SwordError, DSpaceSwordException;

	void replaceMetadataAndMediaResource(Context context, Item item) throws SwordError, DSpaceSwordException;

	void deleteMediaResource(Context context, Item item) throws SwordError, DSpaceSwordException;

	void deleteBitstream(Context context, Bitstream bitstream) throws SwordError, DSpaceSwordException;

	void addResourceContent(Context context, Item item) throws SwordError, DSpaceSwordException;

	void addMetadata(Context context, Item item) throws SwordError, DSpaceSwordException;

	void deleteItem(Context context, Item item) throws SwordError, DSpaceSwordException;

	void retrieveStatement(Context context, Item item) throws SwordError, DSpaceSwordException;

	void modifyState(Context context, Item item) throws SwordError, DSpaceSwordException;

	void resolveState(Context context, Deposit deposit, DepositResult result, VerboseDescription verboseDescription)
            throws DSpaceSwordException;

	void resolveState(Context context, Deposit deposit, DepositResult result, VerboseDescription verboseDescription, boolean containerOperation)
            throws DSpaceSwordException;

	
}
