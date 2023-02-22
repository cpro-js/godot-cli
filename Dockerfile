FROM ubuntu:focal AS godot
# see https://downloads.tuxfamily.org/godotengine/
ENV GODOT_VERSION="4.0"

# Example values: stable, beta3, rc1, alpha2, etc.
# Also change the SUBDIR property when NOT using stable
ENV RELEASE_NAME="rc2"

# This is only needed for non-stable builds (alpha, beta, RC)
# Use an empty string "" when the RELEASE_NAME is "stable"
ENV SUBDIR="/rc2"

ENV GODOT_PLATFORM="linux_x86_64"

WORKDIR /godot

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    unzip \
    wget \
    rename \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/mono/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${GODOT_PLATFORM}.zip \
    && wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/mono/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz

RUN unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${GODOT_PLATFORM}.zip \
    && mv Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${GODOT_PLATFORM} sdk \
    && cd sdk \
    && rename 's/\.x86_64/_x86_64/' * \
    && rename 's/\.x86_32/_x86_32/' * \
    && mv Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${GODOT_PLATFORM} godot

RUN unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz \
    && mv templates templates2 \
    && mkdir -p templates/${GODOT_VERSION}.${RELEASE_NAME}.mono  \
    && mv templates2/* templates/${GODOT_VERSION}.${RELEASE_NAME}.mono


RUN rm -rf Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${GODOT_PLATFORM}.zip
RUN rm -rf Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz

FROM mcr.microsoft.com/dotnet/sdk:6.0

COPY --from=godot /godot/templates /godot/templates
COPY --from=godot /godot/sdk /godot/sdk

RUN mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && cp -r /godot/sdk/.  /usr/local/bin \
    && mkdir -p ~/.local/share/godot/templates && cp -r /godot/templates/.  ~/.local/share/godot/templates \
    && ln -s ~/.local/share/godot/templates ~/.local/share/godot/export_templates \
    && rm -rf /godot
