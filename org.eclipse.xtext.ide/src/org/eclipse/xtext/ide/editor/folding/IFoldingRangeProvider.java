/*******************************************************************************
 * Copyright (c) 2010 Michael Clay and others.
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 *******************************************************************************/
package org.eclipse.xtext.ide.editor.folding;

import java.util.Collection;

import org.eclipse.xtext.resource.XtextResource;
import org.eclipse.xtext.util.CancelIndicator;

import com.google.inject.ImplementedBy;

/**
 * Compute the folding regions in the given document. This is a blocking
 * action when opening the editor in e4, so clients should be careful to
 * not resolve too many cross references in their implementation.
 * 
 * @author Michael Clay - Initial contribution and API
 * @author Sebastian Zarnekow - Refactoring, introduced FoldedPosition
 */
@ImplementedBy(DefaultFoldingRangeProvider.class)
public interface IFoldingRangeProvider {

	/**
	 * @return the list of <code>FoldedPosition</code> for the given document
	 */
	Collection<FoldingRange> getFoldingRanges(XtextResource xtextDocument, CancelIndicator cancelIndicator);

}
