# Shape parameter calculation. Input: the function parameter, which takes an array
# of bits, where 1 is an element belonging to the blob and 0 is a background
# element. Principle of operation: determine when the blob "falls apart" into two
# or more large elements during erosion. Returns a value from
# 0 to 1 (in practice it can be slightly larger than 1). Zero means that the blob
# falls apart quickly (consists of several large parts connected by
# thin necks), one means that it does not fall apart. Works slowly
# (relatively).

module ShapeParameter
using Images
export parameter

function histogram(labels)
    maxlabels = maximum(labels)
    hist = zeros(maxlabels)
    for idx in CartesianIndices(labels)
        label = labels[idx]
        if label > 0
            hist[label] = hist[label] + 1
        end
    end

    return hist
end

function parameter(array :: AbstractArray{Bool}, α = 0.2)
    if length(array) == sum(array)
        error("The array has no background pixels")
    end

    dt = distance_transform(feature_transform(.!array))
    maxdt = maximum(dt)
    n = 0

    eroded = array
    while true
        if sum(eroded) == 0
            break
        end

        labels = label_components(eroded)
        hist = histogram(labels)
        sorted = sort(hist; rev = true)

        if length(sorted) > 1 && sorted[2] > α*sum(sorted)
            break
        end

        n = n + 1
        eroded = dt .> n
    end

    return (n - 1)/maxdt
end

end
