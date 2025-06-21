FROM sagarv1997/n8n:1.99.3
# Using internal n8n image as base image
LABEL maintainer="Sagar Vaghela"

# Copy the script and ensure it has proper permissions
COPY startup.sh /
USER root
RUN chmod +x /startup.sh
USER node
EXPOSE 5678

# Use shell form to help avoid exec format issues
ENTRYPOINT ["/bin/sh", "/startup.sh"]
