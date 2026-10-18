local required={}
local api={id="foodWorks-api"}
package.preload["foodWorks/API"]=function()required.api=(required.api or 0)+1;return api end
package.preload["foodWorks/ApplianceTransactions"]=function()required.transactions=(required.transactions or 0)+1;return{}end
package.preload["foodWorks/PreservationProcesses"]=function()required.preservation=(required.preservation or 0)+1;return{}end
package.preload["foodWorks/FoodInspection"]=function()required.inspection=(required.inspection or 0)+1;return{}end
package.preload["foodWorks/FruitDryingPreview"]=function()required.preview=(required.preview or 0)+1;return{}end
package.preload["foodWorks/AppleDryingServer"]=function()required.dryingServer=(required.dryingServer or 0)+1;return{}end
package.preload["foodWorks/AppleDryingClient"]=function()required.dryingClient=(required.dryingClient or 0)+1;return{}end
package.preload["foodWorks/SweetPreservesAction"]=function()required.preservesAction=(required.preservesAction or 0)+1;return{}end
package.preload["foodWorks/SweetPreservesClient"]=function()required.preservesClient=(required.preservesClient or 0)+1;return{}end
package.preload["foodWorks/SweetPreservesServer"]=function()required.preservesServer=(required.preservesServer or 0)+1;return{}end

assert(dofile(arg[1])==api,"shared loader must return the canonical API")
assert(dofile(arg[2])==api,"server loader must return the canonical API")
assert(dofile(arg[3])==api,"client loader must return the canonical API")
assert(required.api==1,"all realms must share one cached canonical API")
assert(required.transactions==1,"shared loader must install appliance transactions exactly once")
assert(required.preservation==1,"shared loader must install preservation processes exactly once")
assert(required.inspection==1,"client loader must install food inspection exactly once")
assert(required.preview==1,"client loader must install drying preview exactly once")
assert(required.dryingServer==1 and required.dryingClient==1,"realm loaders must install the drying feature")
assert(required.preservesAction==1 and required.preservesClient==1 and required.preservesServer==1,"preserve action, grants and menus load in their proper realms")

package.preload["foodWorks/API"]=nil
package.preload["foodWorks/ApplianceTransactions"]=nil
package.preload["foodWorks/PreservationProcesses"]=nil
package.preload["foodWorks/FoodInspection"]=nil
package.loaded["foodWorks/API"]=nil
package.loaded["foodWorks/ApplianceTransactions"]=nil
package.loaded["foodWorks/PreservationProcesses"]=nil
package.loaded["foodWorks/FoodInspection"]=nil
package.preload["foodWorks/FruitDryingPreview"]=nil
package.loaded["foodWorks/FruitDryingPreview"]=nil
print("foodWorks production load-graph checks passed")
