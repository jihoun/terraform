const {
  CloudFrontClient,
  CreateInvalidationCommand,
} = require("@aws-sdk/client-cloudfront");

const DistributionId = process.env.DISTRIBUTION_ID || "";

const cloudfront = new CloudFrontClient({});

exports.handler = async function () {
  const params = {
    DistributionId,
    InvalidationBatch: {
      CallerReference: new Date().toISOString(),
      Paths: {
        Quantity: 1,
        Items: ["/*"],
      },
    },
  };
  const command = new CreateInvalidationCommand(params);
  await cloudfront.send(command);
};
