
## Implementation of 2-3 search trees
## The two main data structures are the balanced 2-3 trees,
## which are rooted trees in which all leaves are at the same
## depth and in which each node of the tree has either 2 or 3
## children.
## The leaves of the tree also have children; these are 
## the data nodes.
## The tree is stored in two arrays, one array of tree nodes
## and the other of data nodes.


## KDRec is one data node:
##  k: the key of the node
##  d: the data of the node
##  parent: the tree leaf that is the parent of this
##    node.  Note that parent pointers are needed in order
##    to implement iterators.  Parent is set to 0 if the
##    node is deleted.

immutable KDRec{K,D}
    k::K
    d::D
    parent::Int  #0 if deleted
end

## TreeNode is one node of the tree.
## child1,child2,child3:  
##     These are the three children node numbers.
##     If the node is a 2-node (rather than 3), then child3 == 0.
##     If this is a leaf then child1,child2,child3 are indices
##       of data nodes, else they are indices of other tree nodes.
## splitkey1:
##    the minimum key of the subtree at child2; if this is a leaf
##    then it is the key of child2.
## splitkey2: 
##    if child3 > 0 then splitkey2 is the minimum key of the subtree at child3.
##

immutable TreeNode{K}
    splitkey1::K
    splitkey2::K
    child1::Int
    child2::Int
    child3::Int
    parent::Int
end




## The next two functions are called to initialize the tree
## by inserting a dummy tree node with two children, the begin
## and end markers, and then installing those two markers as
## dummy data nodes.

function initializeTree!{K}(defaultKey::K, 
                            tree::Array{TreeNode{K},1})
    resize!(tree,1)
    tree[1] = TreeNode(defaultKey, defaultKey, 1, 2, 0, 0)
end

function initializeData!{K,D}(defaultKey::K, 
                              defaultData::D, 
                              data::Array{KDRec{K,D},1})
    resize!(data, 2)
    data[1] = KDRec(defaultKey, defaultData, 1)
    data[2] = KDRec(defaultKey, defaultData, 1)
end



## Class BalancedTree{K,D} is 'base class' for
## map and multimap.  K = key type, D = data type
## Key type must support < and == operations.
##
## data: the (key,data) pairs of the tree.  
##   The first and second entries of data are dummy placeholders
##   for the beginning and end of the sorted order of the keys
## tree: the nodes of a 2-3 tree that sits above the data.
## rootloc: the index of the entry of tree (i.e., a subscript to 
###  treenodes) that is the tree's root    
## depth: the depth of the tree, (number
##    of tree levels, not counting the data at the bottom)
##    depth==0 means the tree has not been initialized
##    depth==1 means that there is a single root node 
##      whose children are data nodes.


type BalancedTree{K,D}
    data::Array{KDRec{K,D}, 1}
    tree::Array{TreeNode{K}, 1}
    rootloc::Int
    depth::Int
    function BalancedTree(exampleK::K, exampleD::D)
        tree1 = Array(TreeNode{K}, 1)
        initializeTree!(exampleK, tree1)
        data1 = Array(KDRec{K,D}, 2)
        initializeData!(exampleK, exampleD, data1)
        new(data1, tree1, 1, 1)
    end
end





## Function cmp2 checks a tree node with two children
## against a given key, and returns 1 if the given key is
## less than the node's splitkey or 2 else.  Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp2{K}(treenode::TreeNode{K}, k::K, isleaf::Bool)
    ((isleaf && treenode.child2 == 2) || 
     k < treenode.splitkey1)? 1 : 2
end

## Function cmp3 checks a tree node with three children
## against a given key, and returns 1 if the given key is
## less than the node's splitkey1, 2 if less than splitkey2, or
## 3 else. Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp3{K}(treenode::TreeNode{K}, k::K, isleaf::Bool)
    (k < treenode.splitkey1)? 1 :
    (((isleaf && treenode.child3 == 2) || 
     k < treenode.splitkey2)? 2 : 3)
end
 

## The clear function deletes all data in the balanced tree.
## Therefore, it invalidates all iterators.

function clear!{K,D}(t::BalancedTree{K,D})
    resize!(t.data,2)
    resize!(t.tree,1)
    defaultKey = t.tree[1].splitkey1
    t.tree[1] = TreeNode(defaultKey, defaultKey, 1, 2, 0, 0)
    t.depth = 1
    t.rootloc = 1
end

## The findleaf function finds a data item in the tree that
## points to where the given key lives (if it is present), or
## if the key is not present, to the lower bound for the key,
## i.e., the data item that comes immediately before it.  it
## also returns the parent (i.e., tree leaf) of that data item.

function findleaf{K,D}(t::BalancedTree{K,D}, k::K)
    curnode = t.rootloc
    depthcount = 0
    while true
        depthcount += 1
        isleaf = (depthcount == t.depth)
        prevcurnode = curnode
        @inbounds cmp = (t.tree[curnode].child3 == 0)?
            cmp2(t.tree[curnode], k, isleaf) :
            cmp3(t.tree[curnode], k, isleaf)
        @inbounds curnode = (cmp == 1)? t.tree[curnode].child1 :
           ((cmp == 2)? t.tree[curnode].child2 : t.tree[curnode].child3)
        if isleaf
            return prevcurnode, curnode
        end
    end
end

## Function fulldump dumps the entire tree; helpful for debugging.

function fulldump{K,D}(t::BalancedTree{K,D})
    thislevstack = Int[]
    rl = t.rootloc
    dpth = t.depth
    push!(thislevstack, rl)
    println("  rootloc = $rl depth = $dpth")
    nextlevstack = Int[]
    levcount = 0
    for mydepth = 1 : dpth
        isleaf = (dpth == mydepth)
        sz = size(thislevstack,1)
        if sz == 0
            break
        end
        levcount += 1
        println("-------------\n------LEVEL $levcount")
        for i = 1 : sz
            ii = thislevstack[i]
            p = t.tree[ii].parent
            sk1 = t.tree[ii].splitkey1
            sk2 = t.tree[ii].splitkey2
            c1 = t.tree[ii].child1
            c2 = t.tree[ii].child2
            c3 = t.tree[ii].child3
            dt = (mydepth == dpth)? "child/data" : "child/tree"
            if c3 == 0
                println("ii = $ii splitkey1 = /$sk1/ $dt.1 = $c1 $dt.2 = $c2 parent = $p")
                if !isleaf
                    push!(nextlevstack,c1)
                    push!(nextlevstack,c2)
                end
            else
                println("ii = $ii splitkey1 = /$sk1/ splitkey2 = /$sk2/ $dt.1 = $c1 $dt.2 = $c2 $dt.3 =$c3 parent = $p")
                if !isleaf
                    push!(nextlevstack,c1)
                    push!(nextlevstack,c2)
                    push!(nextlevstack,c3)
                end
            end
        end
        thislevstack = nextlevstack
        nextlevstack = Int[]
    end
    println("----- LEAVES---")
    for j = 1 : size(t.data,1)
        k = t.data[j].k
        d = t.data[j].d
        p = t.data[j].parent
        println("j = $j k = /$k/ d = /$d/ parent = /$p/")
    end
end
        

        
    

## Function insert! inserts a new data item into the tree.
## The arguments are the (K,D) pair to insert.
## The return values are a bool and an index.  The
## bool indicates whether the insertion inserted a new record (true) or 
## whether it replaced an existing record (false).
## The index returned is the subscript in t.data where the
## inserted value sits.

function insert!{K,D}(t::BalancedTree{K,D}, k::K, d::D)

    ## First we find the greatest data node that is <= k.
    parent, leafind = findleaf(t, k)

    ## If we have found exactly k in the tree, then we
    ## replace the data associated with k and return.

    if leafind > 2 && t.data[leafind].k == k
        t.data[leafind] = KDRec(k,d,parent)
        return (t.data[leafind].parent == 0), leafind
    end

    # We get here if k was not already found in the tree.
    # In this case we insert a new node.
    depth = t.depth
    newind = size(t.data, 1) + 1
    p1 = parent
    oldchild = leafind
    newchild = newind
    minkeynewchild = k
    splitroot = false
    curdepth = depth


    ## This loop ascends the tree (i.e., follows a path from a leaf to the root)
    ## starting from the parent p1 of 
    ## where the new key k would go.  For each 3-node we encounter
    ## during the ascent, we add a new child, which requires splitting
    ## the 3-node into two 2-nodes.  Then we keep going until we hit the root.
    ## If we encounter a 2-node, then the ascent can stop; we can 
    ## change the 2-node to a 3-node with the new child. Invariant fields
    ## during this loop are:
    ##     p1: the parent node (a tree node index) where the insertion must occur
    ##     oldchild,newchild: the two children of the parent node; oldchild
    ##          was already in the tree; newchild was just added to it.
    ##     minkeynewchild:  This is the key that is the minimum value in
    ##         the subtree rooted at newchild.

    while true
        isleaf = (curdepth == depth)
        oldtreenode = t.tree[p1]

        ## If we hit a 3-node, then there are three cases for how to
        ## insert new child; all three cases involve splitting the
        ## existing node (oldtreenode, numbered p1) into
        ## two new nodes.  One keeps the index p1; the other has 
        ## has a new index called newparentnum.

        if oldtreenode.child3 > 0
            cmp = cmp3(oldtreenode, minkeynewchild, isleaf)
            if cmp == 1
                #  @assert(oldtreenode.child1 == oldchild)
                lefttreenodenew = TreeNode(minkeynewchild, minkeynewchild,
                                           oldtreenode.child1, newchild, 0,
                                           oldtreenode.parent)
                righttreenodenew = TreeNode(oldtreenode.splitkey2, oldtreenode.splitkey2,
                                            oldtreenode.child2, oldtreenode.child3, 0,
                                            oldtreenode.parent)
                minkeynewchild = oldtreenode.splitkey1
                whichp = 1
            elseif cmp == 2
                # @assert(oldtreenode.child2 == oldchild)
                lefttreenodenew = TreeNode(oldtreenode.splitkey1, oldtreenode.splitkey1,
                                          oldtreenode.child1, oldtreenode.child2, 0,
                                          oldtreenode.parent)
                righttreenodenew = TreeNode(oldtreenode.splitkey2, oldtreenode.splitkey2,
                                            newchild, oldtreenode.child3, 0,
                                            oldtreenode.parent)
                whichp = 2
            else
                # @assert(oldtreenode.child3 == oldchild)
                lefttreenodenew = TreeNode(oldtreenode.splitkey1, oldtreenode.splitkey1, 
                                           oldtreenode.child1, oldtreenode.child2, 0,
                                           oldtreenode.parent)
                righttreenodenew = TreeNode(minkeynewchild, minkeynewchild,
                                            oldtreenode.child3, newchild, 0,
                                            oldtreenode.parent)
                minkeynewchild = oldtreenode.splitkey2
                whichp = 2
            end
            # Replace p1 with a new 2-node and insert another 2-node at
            # index newparentnum.

            @inbounds t.tree[p1] = lefttreenodenew
            push!(t.tree, righttreenodenew)
            newparentnum = size(t.tree,1)
            if isleaf

                # If we inserted the leaf above the new data, then
                # we should also insert the new data itself.
                if whichp == 1
                    push!(t.data, KDRec(k,d,p1))
                else
                    push!(t.data, KDRec(k,d,newparentnum))
                end

                # The two children of the node at newparentnum (data nodes) 
                # have a new parent (newparentnum instead of p1)
                # so we have to fix them.

                for childind = 1 : 2
                    procchild = (childind == 1)? righttreenodenew.child1 : righttreenodenew.child2
                    @inbounds olddata = t.data[procchild]
                    if olddata.parent > 0
                        @inbounds t.data[procchild] = KDRec(olddata.k, olddata.d, newparentnum)
                    end
                end
            else

                # If this is not a leaf, we still have to fix the
                # parent fields of the two nodes thta are now children
                ## of the newparent.
                for childind = 1 : 2
                    procchild = (childind == 1)? righttreenodenew.child1 : righttreenodenew.child2
                    oldtreenode = t.tree[procchild]
                    @inbounds t.tree[procchild] = TreeNode(oldtreenode.splitkey1, oldtreenode.splitkey2,
                                                 oldtreenode.child1, oldtreenode.child2,
                                                 oldtreenode.child3, newparentnum)
                end
            end
            ## If p1 is the root (i.e., we have encountered only 3-nodes during
            ## our ascent of the tree), then the root must be split.
            oldchild = p1
            newchild = newparentnum

            if p1 == t.rootloc
                # @assert(curdepth == 1)
                splitroot = true
                break
            end
            @inbounds p1 = t.tree[oldchild].parent
        else

            ## If our ascent reaches a 2-node, then we convert it to
            ## a 3-node by giving it a child3 field that is >0.
            ## Encountering a 2-node halts the ascent up the tree.

            @inbounds t.tree[p1] = (cmp2(oldtreenode, minkeynewchild, isleaf) == 1)?
                TreeNode(minkeynewchild, oldtreenode.splitkey1,
                         oldtreenode.child1, newchild, oldtreenode.child2,
                         oldtreenode.parent) :
                TreeNode(oldtreenode.splitkey1, minkeynewchild, 
                         oldtreenode.child1, oldtreenode.child2, newchild,
                         oldtreenode.parent)
            if isleaf
                push!(t.data,KDRec(k,d,p1))
            end
            break
        end
        curdepth -= 1
    end

    ## Splitroot is set if the ascent of the tree encountered only 3-nodes.
    ## In this case, the root itself was replaced by two nodes, so we need
    ## a new root above those two.

    if splitroot
        curdatasz = size(t.data,1)
        curtreesz = size(t.tree,1)
        dep1 = t.depth
        #println("splitting root depth = $dep1 curdatasz = $curdatasz curtreesz = $curtreesz")

        newroot = TreeNode(minkeynewchild, minkeynewchild, oldchild,
                          newchild, 0, 0)
        push!(t.tree, newroot)
        newrootloc = size(t.tree,1)
        for whichchild = 1 : 2
            procchild = (whichchild == 1)? oldchild : newchild
            childrec = t.tree[procchild]
            t.tree[procchild] = TreeNode(childrec.splitkey1, childrec.splitkey2,
                                         childrec.child1, childrec.child2,
                                         childrec.child3, newrootloc)
        end
        t.rootloc = newrootloc
        t.depth += 1
    end
    sz = size(t.data,1)
    # @assert(size(t.data,1) == newind)
    true, newind
end

## delete!
## Deletes the data item indexed by it.  This current version
## does not shrink the tree; it simply marks the item
## as deleted.

function delete!{K,D}(t::BalancedTree{K,D}, it::Int)
    if it == 1 || it == 2
        error("Attempt to deleted begin or end placeholder")
    end
    if t.data[it].parent == 0
        error("Attempt to deleted key that was already deleted")
    end
    t.data[it] = KDRec(t.data[it].k, t.data[it].d, 0)
end


## pack!(t): This routine packs a tree, which is necessary
## after many deletions.  Packing invalidates all iterators
## because the data items change locations.

function pack!{K,D}(t::BalancedTree{K,D})
    sz = size(t.data,1)
    tmp = Array(KDRec{K,D}, sz - 2)
    for i = 3 : sz
        tmp[i-2] = t.data[i]
    end
    clear!(t)
    sz -= 2
    for i = 1 : sz
        insert!(t, tmp[i].k, tmp[i].d)
    end
end


## nextloc0: returns the next item in the tree according to the
## sort order, given an index i (subscript of t.data) of a current
## item. Both the input and output may be deleted entries.
## The second argument is the parent index of the entry.
## The routine returns 2 if there is no next item (i.e., we started
## from the last one in the sorted order).


function nextloc0{K,D}(t::BalancedTree{K,D}, p::Int, i::Int)
    ii = i
    nextchild = 0
    depthp = t.depth
    while true
        if depthp < t.depth
            @inbounds p = t.tree[ii].parent
        end
        @inbounds if t.tree[p].child1 == ii
            @inbounds nextchild = t.tree[p].child2
            break
        end
        @inbounds if t.tree[p].child2 == ii && t.tree[p].child3 > 0
            @inbounds nextchild = t.tree[p].child3
            break
        end
        #if t.tree[p].child3 != ii && (t.tree[p].child2 != ii || t.tree[p].child3 > 0)
        #    tdepth = t.depth
        #    c1 = t.tree[p].child1
        #    c2 = t.tree[p].child2
        #    c3 = t.tree[p].child3
        #    sk1 = t.tree[p].splitkey1
        #    sk2 = t.tree[p].splitkey2
        #    println("t.depth = $tdepth depthp = $depthp p = $p ii = $ii c1 = $c1 c2 = $c2 c3 = $c3 sk1 = $sk1 sk2 = $sk2")
        #end

        #@assert((t.tree[p].child2 == ii && t.tree[p].child3 == 0) || 
        #        t.tree[p].child3 == ii)
        if p == t.rootloc
            return 0,2
        end
        ii = p
        depthp -= 1
    end
    while true
        if depthp == t.depth
            return p, nextchild
        end
        p = nextchild
        @inbounds nextchild = t.tree[p].child1
        depthp += 1
    end
end

## nextloc advances i (an index into t.data) to the
## next nondeleted data item in the sorted order.  It returns
## 2 if we are at the end of the data.  The input
## must be a non-deleted entry.  The output is
## also nondeleted since the routine skips over
## deleted items
    
function nextloc{K,D}(t::BalancedTree{K,D}, i::Int)
    if i == 2
        error("Attempt to advance past end of balanced tree")
    end
    ii = i
    @inbounds p = t.data[i].parent
    while true
        newp, newii = nextloc0(t, p, ii)
        @inbounds if newii == 2 || t.data[newii].parent > 0
            return newii
        end
        p, ii = newp, newii
    end
end



## beginloc returns the index (into t.data) of the first item in the 
## sorted order of the tree.  It assumes the tree is not in the null
## state.
function beginloc{K,D}(t::BalancedTree{K,D})
    nextloc(t,1)
end



## A Map is a wrapper around balancedTree.

type Map{K,D} <: Associative{K,D}
    bt::BalancedTree{K,D}
    function Map(exampleK::K, exampleD::D)
        bt1 = BalancedTree{K,D}(exampleK, exampleD)
        new(bt1)
    end
end

## A map iterator is a small structure for iterating
## over the items in a tree in sorted order.  It is
## a wrapper around an Int; the int is the index
## of the current item in t.tree.  A valid iterator
## should never point to a deleted item.

immutable MapIterator{K,D}
    address::Int
end


## This function implements m[k]; it returns the
## data item associated with key k.

function getindex{K,D}(m::Map{K,D}, k::K)
    p,i = findleaf(m.bt, k)
    if i < 3 || m.bt.data[i].k != k || m.bt.data[i].parent == 0
        error("getindex called for key not found")
    end
    m.bt.data[i].d
end

## This function implements m[k]=d; it sets the 
## data item associated with key k equal to d.

function setindex!{K,D}(m::Map{K,D}, d::D, k::K)
    insert!(m.bt, k, d)
end

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.
        
function find{K,D}(m::Map{K,D}, k::K)
    p,l = findleaf(m.bt, k)
    if l > 2 && m.bt.data[l].k == k && m.bt.data[l].parent > 0
        return MapIterator{K,D}(l)
    else
        return MapIterator{K,D}(2)
    end
end

## This function inserts an item into the tree.
## Unlike m[k]=d, it also returns a bool and an iterator.
## The ## bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The iterator points to the newly inserted item.

function insert!{K,D}(m::Map{K,D}, k::K, d::D)
    b, i = insert!(m.bt, k, d)
    b, MapIterator{K,D}(i)
end

## Function delete! deletes an item at a given 
## iterator position.

function delete!{K,D}(m::Map{K,D}, ii::MapIterator{K,D})
    delete!(m.bt, ii.address)
end


## Function beginmap returns the iterator that points
## to the first sorted order of the tree.  It returns
## the end marker if the tree is empty.

function beginmap{K,D}(m::Map{K,D})
    MapIterator{K,D}(beginloc(m.bt))
end

## Function atend tests whether an iterator is at the
## end marker.

function atend{K,D}(m::Map{K,D}, ii::MapIterator{K,D})
    ii.address == 2
end


## Function next takes an iterator and returns the
## next iterator in the sorted order.  Deleted items
## are skipped.

function next{K,D}(m::Map{K,D}, ii::MapIterator{K,D})
     MapIterator{K,D}(nextloc(m.bt, ii.address))
end


## Function m[i], where i is an iterator, returns the
## (k,d) pair indexed by i.

function getindex{K,D}(m::Map{K,D}, ii::MapIterator{K,D})
    addr = ii.address
    if addr < 3
        error("Attempt to retrieve data at end of map")
    end
    if m.bt.data[addr].parent == 0
        error("Attempt to access deleted entry")
    end
    m.bt.data[addr].k, m.bt.data[addr].d
end


## This function takes a key and returns an iterator
## to the first item in the tree that is >= the given
## key in the sorted order.  It returns the end marker
## if there is none.

function firstKeySameOrGreater{K,D}(m::Map{K,D}, k::K)
    p,i = findleaf(m.bt, k)
    if i > 2 && m.bt.data[i].k == k && m.bt.data[i].parent > 0
        return MapIterator{K,D}(i)
    end
    MapIterator{K,D}(nextloc(m.bt, i))
end

## This function takes a key and returns an iterator
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the end marker
## if there is none.

function firstKeyGreater{K,D}(m::Map{K,D}, k::K)
    p,i = findleaf(m.bt, k)
    MapIterator{K,D}(nextloc(m.bt, i))
end

## This function clears a map -- all items deleted.

function clear!{K,D}(m::Map{K,D})
    clear!(m.bt)
end


## pack!(t): This routine packs a tree, which is necessary
## after many deletions.  Iterators to the old map are not valid
## for the new map
## because the data items change locations.  It returns
## a new map, which is the packed version of the old map.

function pack!{K,D}(m::Map{K,D})
    pack!(m.bt)
end



function test1()
    m1 = Map{ASCIIString, ASCIIString}("", "")
    kdarray = ["hello", "jello", "alpha", "beta", "fortune", "random",
               "july", "wednesday"]
    for i = 1 : div(size(kdarray,1), 2)
        k = kdarray[i*2-1]
        d = kdarray[i*2]
        println("- inserting: k = $k d = $d")
        m1[k] = d
        # fulldump(m1.bt)
    end
    i1 = beginmap(m1)
    while !atend(m1,i1)
        k,d = m1[i1]
        println("+ reading: k = $k, d = $d")
        i1 = next(m1,i1)
    end
end




function test2()
    NSTRINGPAIR = 50000
    m1 = Map{ASCIIString, ASCIIString}("", "")
    h = open("wordsScram.txt")
    strlist = ASCIIString[]
    for j = 1 : NSTRINGPAIR * 2
        push!(strlist, readline(h))
    end
    close(h)
    for trial = 1 : 100
        clear!(m1)
        count = 1
        for j = 1 : NSTRINGPAIR
            k = strlist[count]
            d = strlist[count + 1]
            m1[k] = d
            count += 2
        end

        spec = div(NSTRINGPAIR * 3,4)
        l = beginmap(m1)
        for j = 1 : spec
            l = next(m1,l)
        end
        k,d = m1[l]
        #println("word pair #$spec k = $k d = $d")
    end
end







export BalancedTree
export Map
export MapIterator
export setindex
export getindex
export insert!
export find
export beginMap
export atEnd
export next
export firstkeySameOrGreater
export firstkeyGreater
export clear!
export pack!
export test1
export test2


                     
    
    
    
    
        
